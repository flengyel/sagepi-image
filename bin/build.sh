# 0) Enter the build context
cd sagepi-image

# 1) CA handling (deterministic; TLS verification stays ON)
#    This copies the host bundle to ./host-ca-certificates.crt
bin/copy-host-certs.sh

# 2) Purge stale/incompatible image (example tag; edit if you used a different IMAGE)
podman image rm -f localhost/sagepi-sagemath:10.7-pycryptosat || true
podman image prune -f
podman system prune -f

# 3) Build (no cache; pinned ref; commit recorded at /sage/SAGE_COMMIT)
bin/build-nocache.sh

# 4) Verify (arch + Sage commit + pycryptosat version)
bin/checkimage.sh


