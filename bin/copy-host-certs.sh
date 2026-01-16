#!/usr/bin/env bash
set -euo pipefail

# Create ./host-ca-certificates.crt deterministically from the host's CA bundle.
#
# TLS verification remains enabled. The Containerfile copies this file into
# /etc/ssl/certs/ca-certificates.crt.

prog="$(basename "$0")"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

src="/etc/ssl/certs/ca-certificates.crt"
out="${repo_root}/host-ca-certificates.crt"
extras=()

usage() {
  cat <<'USAGE'
Usage: bin/copy-host-certs.sh [--src /path/to/ca-bundle.crt] [--out /path/to/host-ca-certificates.crt] [--extra /path/to/extra-ca.crt]...

Copies a host CA bundle into the repo build context as host-ca-certificates.crt.

Options:
  --src FILE    Source CA bundle (default: /etc/ssl/certs/ca-certificates.crt)
  --out FILE    Output file (default: ./host-ca-certificates.crt)
  --extra FILE  Append additional PEM certs to the output bundle (may be repeated)
USAGE
}

die() {
  echo >&2 "${prog}: ERROR: $*"
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --src)
      [[ $# -ge 2 ]] || die "--src requires a path"
      src="$2"; shift 2 ;;
    --out)
      [[ $# -ge 2 ]] || die "--out requires a path"
      out="$2"; shift 2 ;;
    --extra)
      [[ $# -ge 2 ]] || die "--extra requires a path"
      extras+=("$2"); shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      die "unknown argument: $1" ;;
  esac
done

[[ -r "${src}" ]] || die "source CA bundle not readable: ${src}"

out_dir="$(dirname "${out}")"
[[ -d "${out_dir}" ]] || die "output directory does not exist: ${out_dir}"

# Write via temp file then atomically move into place.
tmp="$(mktemp "${out}.tmp.XXXXXXXX")"
trap 'rm -f "${tmp}"' EXIT

cat "${src}" > "${tmp}"

for f in "${extras[@]}"; do
  [[ -r "${f}" ]] || die "extra CA file not readable: ${f}"
  printf '\n' >> "${tmp}"
  cat "${f}" >> "${tmp}"
done

chmod 0644 "${tmp}"
mv -f "${tmp}" "${out}"
trap - EXIT

sha256sum "${out}" | tee "${out}.sha256"

echo "Wrote: ${out}"
