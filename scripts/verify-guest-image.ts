import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";

import { MiB, NetworkPolicy, Sandbox, type Sandbox as SandboxInstance } from "microsandbox";

const image = process.env["PLUXEL_GUEST_IMAGE"]?.trim();
if (!image || !/@sha256:[a-f0-9]{64}$/u.test(image)) {
  throw new Error("PLUXEL_GUEST_IMAGE must be an OCI image reference pinned by sha256 digest.");
}

const temporaryRoot = await mkdtemp(resolve(tmpdir(), "pluxel-guest-smoke-"));
const workspace = resolve(temporaryRoot, "workspace");
const readonly = resolve(temporaryRoot, "readonly");
await mkdir(workspace);
await mkdir(readonly);
await writeFile(resolve(readonly, "input.txt"), "READONLY_OK\n", "utf8");

const sandboxName = `pluxel-guest-verify-${createHash("sha256")
  .update(temporaryRoot)
  .digest("hex")
  .slice(0, 20)}`;
let sandbox: SandboxInstance | null = null;

try {
  sandbox = await Sandbox.builder(sandboxName)
    .image(image)
    .pullPolicy("never")
    .cpus(2)
    .memory(MiB(2048))
    .workdir("/workspace")
    .security("restricted")
    .idleTimeout(60)
    .maxDuration(300)
    .volume("/workspace", (volume) => volume.bind(workspace).hostPermissions("private"))
    .volume("/workspace/readonly", (volume) => volume.bind(readonly).readonly().nosuid().nodev())
    .network((network) => network.policy(NetworkPolicy.none()))
    .replaceWithTimeout(15_000)
    .create();

  const smoke = await sandbox.execWith("python", (execution) =>
    execution.args(["/opt/pluxel/verify-guest.py"]).cwd("/workspace").timeout(180_000),
  );
  assert.equal(
    smoke.code,
    0,
    `Guest capability smoke failed.\nstdout:\n${smoke.stdout()}\nstderr:\n${smoke.stderr()}`,
  );

  const readonlyWrite = await sandbox.execWith("sh", (execution) =>
    execution.args(["-c", "printf MUTATED > readonly/input.txt"]).cwd("/workspace").timeout(30_000),
  );
  assert.notEqual(readonlyWrite.code, 0, "guest unexpectedly wrote to a read-only input mount");
  assert.equal(await readFile(resolve(readonly, "input.txt"), "utf8"), "READONLY_OK\n");

  const result = JSON.parse(
    await readFile(resolve(workspace, "guest-smoke-result.json"), "utf8"),
  ) as { readonly status?: unknown; readonly marker?: unknown };
  assert.equal(result.status, "ok");
  assert.equal(result.marker, "PLUXEL_GUEST_OK_7319");
  process.stdout.write(`Pluxel guest verified in a network-disabled MicroVM: ${image}\n`);
} finally {
  if (sandbox) {
    await sandbox.stopWithTimeout(10_000).catch(() => sandbox?.killWithTimeout(5_000));
    await Sandbox.remove(sandboxName).catch(() => undefined);
  }
  await rm(temporaryRoot, { recursive: true, force: true });
}
