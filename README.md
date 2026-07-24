# Pluxel Report Guest Container

Public, credential-free document-analysis guest for the Pluxel Report Agent. The image derives from
a digest-pinned Jupyter SciPy base and is published as:

```text
ghcr.io/ahdg6/report-guest-container:<release>@sha256:<amd64-digest>
```

It adds a narrow tool contract for searching and navigating files, local workspace history with
Jujutsu (`jj`), PDF inspection, DOCX/PPTX, modern and legacy Excel, OpenDocument processing, archives, images, and
offline fallback OCR. LibreOffice is deliberately not included. The complete machine-readable
contract is in `guest-capabilities.json`.

The Agent uses the small native workflow directly: `jj status`, `jj diff`, `jj describe`, `jj new`,
`jj log`, and `jj show`. There is no staging area and no remote repository is required. The image
does not emulate Git commands or add a second version-control abstraction. The concise system prompt
covers routine use; `/opt/pluxel/JJ_AGENT_GUIDE.md` is an on-demand read-only reference for
checkpoint, history, and safe path restoration.

Report workspaces initialize with `jj git init --no-colocate .`, so the Git backend remains private
beneath `.jj/` and no top-level `.git/` is created. System configuration excludes the read-only
`sources/`, `evidence/`, `searches/`, `templates/`, and `tools/` mounts from snapshots. The Report
Agent host records existing writable files as the clean `Initial workspace` baseline and treats
`.jj/` as internal workspace state. The image deliberately does not initialize a repository before
`/workspace` is mounted.

## Trust and release model

- The base image, every consumer reference, and the downloaded amd64 `jj` release are pinned by
  digest or SHA-256.
- Runtime MicroVMs use `pullPolicy=never`, restricted security, and disabled networking.
- The GHCR package is public; the guest contains no provider credentials or private application code.
- A release candidate is promoted without rebuilding only after a real amd64 Microsandbox MicroVM
  executes the complete file-operation smoke test.
- The workflow emits SBOM/provenance and signs the verified amd64 digest with GitHub OIDC and
  Cosign.
- Tesseract is an offline fallback. Its output remains unconfirmed machine-derived content.

GitHub requires the package owner to change a newly created container package to public once in its
package settings. Every release then verifies an anonymous manifest request before MicroVM testing
or promotion, so later visibility regressions fail closed.

Publishing is automatic when an immutable numeric release tag such as `2026.07.0` is pushed for a
commit contained in `main`; the workflow can also be dispatched manually. Existing release tags are
never moved.

The standard GitHub-hosted amd64 runner exposes KVM. The release workflow uses that real KVM device
and never substitutes a container-only smoke test for the MicroVM gate. The Guest is intentionally
published for linux/amd64 only.

## Local verification

Linux, KVM, `libcap-ng`, Node 24, and pnpm 11 are required:

```sh
corepack enable
pnpm install --frozen-lockfile
PLUXEL_GUEST_IMAGE=ghcr.io/ahdg6/report-guest-container:<tag>@sha256:<digest> \
  pnpm verify
```

The command performs the host-side pull once. The actual MicroVM starts with networking disabled and
`pullPolicy=never`; its smoke test also initializes an offline non-colocated `jj` repository,
verifies status, diff, describe/new checkpoints, log, show, and restore operations, and opens a real
OLE/BIFF8 `.xls` fixture with `xlrd`. Modern OOXML workbooks use `openpyxl`; binary `.xlsb` files use
`pyxlsb`. The smoke test also opens OOXML content deliberately carrying a wrong `.xls` extension by
passing a binary stream to `openpyxl`, matching the Agent's content-first format routing.
