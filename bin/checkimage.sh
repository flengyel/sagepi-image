#!/usr/bin/env bash
set -euo pipefail

# Minimal runtime verification of the built image:
#   - platform: linux/arm64
#   - Sage commit file exists (and optionally matches SAGE_GIT_COMMIT)
#   - pycryptosat version matches PYCRYPTOSAT_VERSION

SAGE_GIT_REF="${SAGE_GIT_REF:-10.7}"
SAGE_GIT_COMMIT="${SAGE_GIT_COMMIT:-}"
PYCRYPTOSAT_VERSION="${PYCRYPTOSAT_VERSION:-5.11.21}"

IMAGE="${IMAGE:-localhost/sagequeue-sagemath:${SAGE_GIT_REF}-pycryptosat}"

prog="$(basename "$0")"

if ! command -v podman >/dev/null 2>&1; then
  echo >&2 "${prog}: ERROR: podman not found in PATH"
  exit 127
fi

platform="$(podman image inspect "${IMAGE}" --format '{{.Os}}/{{.Architecture}}')"
echo "Image: ${IMAGE}"
echo "Image platform: ${platform}"
if [[ "${platform}" != "linux/arm64" ]]; then
  echo >&2 "${prog}: ERROR: expected linux/arm64, got ${platform}"
  exit 1
fi

sage_commit="$(podman run --rm --platform linux/arm64 "${IMAGE}" cat /sage/SAGE_COMMIT | tr -d '\r\n')"
echo "Sage commit: ${sage_commit}"
if [[ -n "${SAGE_GIT_COMMIT}" && "${sage_commit}" != "${SAGE_GIT_COMMIT}" ]]; then
  echo >&2 "${prog}: ERROR: Sage commit mismatch: expected ${SAGE_GIT_COMMIT}, got ${sage_commit}"
  exit 1
fi

pyc_ver="$(podman run --rm --platform linux/arm64 "${IMAGE}" \
  bash -c 'set -euo pipefail; cd /sage && ./sage -python -c "import pycryptosat; print(pycryptosat.__version__)"' \
  | tr -d '\r\n')"
echo "pycryptosat: ${pyc_ver}"
if [[ "${pyc_ver}" != "${PYCRYPTOSAT_VERSION}" ]]; then
  echo >&2 "${prog}: ERROR: pycryptosat version mismatch: expected ${PYCRYPTOSAT_VERSION}, got ${pyc_ver}"
  exit 1
fi

echo "OK"
