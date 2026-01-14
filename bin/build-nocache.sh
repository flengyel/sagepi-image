#!/bin/bash

podman build --no-cache -f Containerfile \
  --build-arg SAGE_GIT_REF=10.7 \
  --build-arg MAKE_JOBS=4 \
  -t localhost/sagequeue-sagemath:10.7-pycryptosat .

