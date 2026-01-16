#!/usr/bin/env bash
set -euo pipefail

# Deterministic-ish build wrapper for rootless Podman on Raspberry Pi (linux/arm64).
#
# Notes:
# - TLS verification is not disabled.
# - You are expected to run bin/copy-host-certs.sh first to generate
#   ./host-ca-certificates.crt in the build context.

SAGE_GIT_REF="${SAGE_GIT_REF:-10.7}"
SAGE_GIT_COMMIT="${SAGE_GIT_COMMIT:-}"
MAKE_JOBS="${MAKE_JOBS:-4}"
PYCRYPTOSAT_VERSION="${PYCRYPTOSAT_VERSION:-5.11.21}"
CONFIGURE_FLAGS="${CONFIGURE_FLAGS:---enable-cryptominisat}"

CONTAINERFILE="${CONTAINERFILE:-Containerfile}"
IMAGE="${IMAGE:-localhost/sagequeue-sagemath:${SAGE_GIT_REF}-pycryptosat}"

prog="$(basename "$0")"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v podman >/dev/null 2>&1; then
  echo >&2 "${prog}: ERROR: podman not found in PATH"
  exit 127
fi

ca_file="${repo_root}/host-ca-certificates.crt"
if [[ ! -s "${ca_file}" ]]; then
  echo >&2 "${prog}: ERROR: missing or empty ${ca_file}"
  echo >&2 "${prog}:        run: bin/copy-host-certs.sh"
  exit 2
fi

set -x
podman build --no-cache --platform linux/arm64 -f "${CONTAINERFILE}" \
  --build-arg "SAGE_GIT_REF=${SAGE_GIT_REF}" \
  --build-arg "SAGE_GIT_COMMIT=${SAGE_GIT_COMMIT}" \
  --build-arg "MAKE_JOBS=${MAKE_JOBS}" \
  --build-arg "CONFIGURE_FLAGS=${CONFIGURE_FLAGS}" \
  --build-arg "PYCRYPTOSAT_VERSION=${PYCRYPTOSAT_VERSION}" \
  -t "${IMAGE}" "${repo_root}"
