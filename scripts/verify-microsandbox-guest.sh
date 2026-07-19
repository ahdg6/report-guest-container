#!/bin/sh
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${PLUXEL_GUEST_IMAGE:?Set PLUXEL_GUEST_IMAGE to a digest-pinned published guest image}

case "$image" in
  *@sha256:*) ;;
  *)
    echo "PLUXEL_GUEST_IMAGE must end in @sha256:<64 lowercase hex characters>." >&2
    exit 1
    ;;
esac
digest=${image##*@sha256:}
case "$digest" in
  "" | *[!0-9a-f]*)
    echo "PLUXEL_GUEST_IMAGE must end in @sha256:<64 lowercase hex characters>." >&2
    exit 1
    ;;
esac
if [ "${#digest}" -ne 64 ]; then
  echo "PLUXEL_GUEST_IMAGE must end in @sha256:<64 lowercase hex characters>." >&2
  exit 1
fi

if [ -n "${FLATPAK_ID:-}" ] && command -v flatpak-spawn >/dev/null 2>&1; then
  exec flatpak-spawn --host sh -lc \
    'PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:$PATH"; export PATH; cd "$1"; export PLUXEL_GUEST_IMAGE="$2"; corepack pnpm exec microsandbox --info pull "$2"; exec corepack pnpm exec tsx scripts/verify-guest-image.ts' \
    sh "$root_dir" "$image"
fi

cd "$root_dir"
corepack pnpm exec microsandbox --info pull "$image"
exec corepack pnpm exec tsx scripts/verify-guest-image.ts
