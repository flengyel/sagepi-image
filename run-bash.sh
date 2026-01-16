#!/usr/bin/env bash
set -euo pipefail

# Exec an interactive shell inside the running container.
# Container name is fixed for compatibility with podman-compose.yml.

if ! command -v podman >/dev/null 2>&1; then
  echo >&2 "ERROR: podman not found in PATH"
  exit 127
fi

exec podman exec -it sagemath /bin/bash
