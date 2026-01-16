#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper to:
#   1) generate host-ca-certificates.crt (TLS verification stays ON)
#   2) purge stale/incompatible images
#   3) build (no cache)
#   4) verify (arch + Sage commit + pycryptosat version)

prog="$(basename "$0")"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

# 1) CA handling (deterministic; TLS verification stays ON)
#    This copies the host bundle to ./host-ca-certificates.crt
./bin/copy-host-certs.sh

# 2) Purge stale/incompatible images
#    Keep legacy tag removal for compatibility with older workflows.
SAGE_GIT_REF="${SAGE_GIT_REF:-10.7}"
IMAGE="${IMAGE:-localhost/sagequeue-sagemath:${SAGE_GIT_REF}-pycryptosat}"

podman image rm -f localhost/sagepi-sagemath:10.7-pycryptosat || true
podman image rm -f "${IMAGE}" || true

podman image prune -f
podman builder prune -f

# 3) Build (no cache; pinned ref; commit recorded at /sage/SAGE_COMMIT)
./bin/build-nocache.sh

# 4) Verify (arch + Sage commit + pycryptosat version)
./bin/checkimage.sh
