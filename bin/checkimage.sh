#!/bin/bash
podman image inspect localhost/sagequeue-sagemath:10.7-pycryptosat \
  --format '{{.Os}}/{{.Architecture}}'
# expect: linux/arm64
podman run --rm localhost/sagequeue-sagemath:10.7-pycryptosat \
  bash -c 'cd /sage && ./sage -python -c "import pycryptosat; print(pycryptosat.__version__)"'
