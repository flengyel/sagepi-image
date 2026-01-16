# SagePi Image

Build an ARM64-native SageMath 10.7 + `pycryptosat==5.11.21` container for Raspberry Pi 5.

This repository:
- builds the image used by **sagequeue** (tag compatibility is preserved), and
- serves as a standalone full-featured Sage container on the Pi (via `podman-compose.yml`, `man-up.sh`, `man-down.sh`, `run-bash.sh`).

## Compatibility contract (do not rename)

The image name/tag used by `podman-compose.yml` (and expected by sagequeue) is:

- `localhost/sagequeue-sagemath:${SAGE_TAG:-10.7}-pycryptosat`

The running container name is:

- `sagemath`

## Determinism / audit hooks

Build args:
- `SAGE_GIT_REF` (default: `10.7`)
- `SAGE_GIT_COMMIT` (default: empty; if set, build fails unless the ref resolves to that commit)
- `MAKE_JOBS` (default: `4`)
- `CONFIGURE_FLAGS` (default: `--enable-cryptominisat`)
- `PYCRYPTOSAT_VERSION` (default: `5.11.21`)

Recorded in-image:
- `/sage/SAGE_REF`
- `/sage/SAGE_COMMIT`
- `/etc/ssl/certs/ca-certificates.crt.sha256` (the exact CA bundle copied into the image)

Build-time verification:
- `./sage -python -c "import pycryptosat; print(pycryptosat.__version__)"` is executed during the image build and asserts the version matches `PYCRYPTOSAT_VERSION`.

Constraint enforced by policy:
- No bash login-shell invocations are used; only non-login `bash -c`.

## Corporate TLS / custom CA bundle (TLS verification stays enabled)

The image build expects a CA bundle file in the build context:

- `./host-ca-certificates.crt`

Generate it deterministically from the host:

```bash
./bin/copy-host-certs.sh
```

Optionally append one or more additional PEM certificates:

```bash
./bin/copy-host-certs.sh --extra /path/to/corp-root-ca.crt
```

The generated files are git-ignored:
- `host-ca-certificates.crt`
- `host-ca-certificates.crt.sha256`

## Build (rootless Podman on Raspberry Pi)

Typical workflow:

```bash
./bin/copy-host-certs.sh
./bin/build-nocache.sh
./bin/checkimage.sh
```

Or the one-shot wrapper:

```bash
./bin/build.sh
```

### Explicit `podman build` command

```bash
podman build --no-cache --platform linux/arm64 -f Containerfile \
  --build-arg SAGE_GIT_REF=10.7 \
  --build-arg SAGE_GIT_COMMIT= \
  --build-arg MAKE_JOBS=4 \
  --build-arg CONFIGURE_FLAGS="--enable-cryptominisat" \
  --build-arg PYCRYPTOSAT_VERSION=5.11.21 \
  -t localhost/sagequeue-sagemath:10.7-pycryptosat .
```

## Purging stale/incompatible images

```bash
podman image rm -f localhost/sagequeue-sagemath:10.7-pycryptosat || true
podman image prune -f
podman builder prune -f
```

## Run standalone (Jupyter)

1) Create a repo-local venv with `podman-compose`:

```bash
./bin/venvfix.sh
```

2) Start the container:

```bash
./man-up.sh --follow
```

3) Stop the container:

```bash
./man-down.sh
```

4) Get an interactive shell inside the running container:

```bash
./run-bash.sh
```
