# basalt-docker

A container image for [Basalt](https://github.com/jesdga95/basalt), a local
inference engine that keeps what does not fit in VRAM (the experts of a
mixture-of-experts model) in system RAM, and its OpenAI- and
Anthropic-compatible server.

The image builds Basalt from a release tag, with every model it supports, and
ships the same file set as the upstream `linux-x64` release, on the CUDA
runtime base.

## Requirements

- An x86-64 host with AVX2 and an NVIDIA Blackwell GPU with compute
  capability 12.0. The image is built for that architecture only (upstream
  also supports the Arm64 GB10, which this image does not).
- A driver that supports CUDA 13.4, and the NVIDIA Container Toolkit.
- Docker with BuildKit (the default since Docker 23).

## Quick start

```sh
git clone https://github.com/Netdex/basalt-docker
cd basalt-docker
cp config.example.json config.json
mkdir models cache
# put your .basalt pack in ./models and point config.json at it
openssl rand -hex 32 > api-key
docker compose up -d --build
```

The server listens on port 8080:

```sh
curl http://localhost:8080/v1/models -H "Authorization: Bearer $(cat api-key)"
```

## Prebuilt images

A daily workflow follows upstream releases: when a new one appears it bumps
`BASALT_REF` here and publishes the image as
`ghcr.io/netdex/basalt-docker:<version>` and `:latest`.

```sh
docker pull ghcr.io/netdex/basalt-docker:0.6.0
```

To use it from `compose.yaml`, replace `build: .` and `image:` with
`image: ghcr.io/netdex/basalt-docker:0.6.0`.

## Build arguments

| Argument       | Default  | Meaning                                       |
| -------------- | -------- | --------------------------------------------- |
| `BASALT_REF`   | `v0.6.0` | Upstream release tag to build (`vX.Y.Z`)      |
| `BASALT_MODELS` | `all`   | Models to build: `all`, or a `;`-separated list of architecture ids |
| `CUDA_VERSION` | `13.4.3` | `nvidia/cuda` base image version              |

```sh
docker build --build-arg BASALT_REF=v0.5.7 -t basalt:0.5.7 .
docker build --build-arg BASALT_MODELS=qwen4exp -t basalt:flash-next .
```

`BASALT_MODELS` takes upstream's architecture ids (`qwen4exp` is
Qwen3.8-Flash-Next); see upstream's
[building](https://github.com/jesdga95/basalt/blob/master/docs/building.md#building-only-some-models)
for the list. A smaller set builds much faster.

`BASALT_REF` must be a release tag: the build packages the result with
upstream's `tools/package_release.py`, which checks the tag against the
version in `CMakeLists.txt`.

## Runtime

| Path / variable        | Purpose                                                        |
| ---------------------- | -------------------------------------------------------------- |
| `/etc/basalt.json`     | Server config (`BASALT_CONFIG` to move it)                     |
| `/models`              | Model packs, referenced by path from the config                |
| `/root/.cache/basalt`  | Engine cache; keep it on a volume to skip work on restart      |
| `BASALT_API_KEY_FILE`  | File holding the API key, default `/run/secrets/basalt-api-key` |

Basalt refuses an API key in its config file. The entrypoint passes
`BASALT_API_KEY_FILE` to the server as `--api-key-file`, so the key never
appears in the process's command line. If the file is absent the server runs
without a key and warns that it is open to the network.

Arguments after the image name are passed through to `basalt serve`:

```sh
docker run --gpus all ... basalt:0.6.0 --port 9000
```

The config format is documented upstream in
[docs/configuration](https://github.com/jesdga95/basalt/tree/master/docs/configuration/index.md);
`tools/migrations/config_v1_to_v2.py` in the image converts an older file.
`memlock` is unlimited and `shm_size` raised in `compose.yaml` because the
engine pins host memory for expert uploads.

## License

MIT for the files in this repository. Basalt itself is MIT-licensed by its
author; see the upstream repository and its `THIRD_PARTY_LICENSES`.
