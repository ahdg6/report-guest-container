# Pluxel Report Guest Container

Public, credential-free document-analysis guest for the Pluxel Report Agent. The image derives from
a digest-pinned Jupyter SciPy base and is published as:

```text
ghcr.io/ahdg6/report-guest-container:<release>@sha256:<multi-architecture-digest>
```

It adds a narrow tool contract for searching and navigating files, PDF inspection, DOCX/PPTX/XLSX
and OpenDocument processing, archives, images, and offline fallback OCR. LibreOffice is deliberately
not included. The complete machine-readable contract is in `guest-capabilities.json`.

## Trust and release model

- The base image and every consumer reference are pinned by digest.
- Runtime MicroVMs use `pullPolicy=never`, restricted security, and disabled networking.
- The GHCR package is public; the guest contains no provider credentials or private application code.
- A release candidate is promoted without rebuilding only after real amd64 and arm64 Microsandbox
  MicroVMs execute the complete file-operation smoke test.
- The workflow emits SBOM/provenance and signs the verified multi-architecture digest with GitHub
  OIDC and Cosign.
- Tesseract is an offline fallback. Its output remains unconfirmed machine-derived content.

Publishing is automatic when an immutable numeric release tag such as `2026.07.0` is pushed for a
commit contained in `main`; the workflow can also be dispatched manually. Existing release tags are
never moved.

## Local verification

Linux, KVM, `libcap-ng`, Node 24, and pnpm 11 are required:

```sh
corepack enable
pnpm install --frozen-lockfile
PLUXEL_GUEST_IMAGE=ghcr.io/ahdg6/report-guest-container:<tag>@sha256:<digest> \
  pnpm verify
```

The command performs the host-side pull once. The actual MicroVM starts with networking disabled and
`pullPolicy=never`.
