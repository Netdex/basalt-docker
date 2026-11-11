# basalt-docker

A container image for [Basalt](https://github.com/jesdga95/basalt), a local
inference engine for mixture-of-experts models that keeps the experts that do
not fit in VRAM in system RAM, and its OpenAI- and Anthropic-compatible server.

The image builds Basalt from a release tag and ships the same file set as the
upstream `linux-x64` release, on the CUDA runtime base.

## Requirements

- An NVIDIA GPU with compute capability 12.0 (Blackwell). Basalt builds for
  that architecture only.
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

## Build arguments

| Argument       | Default  | Meaning                                       |
| -------------- | -------- | --------------------------------------------- |
| `BASALT_REF`   | `v0.3.2` | Upstream release tag to build (`vX.Y.Z`)      |
| `CUDA_VERSION` | `13.4.3` | `nvidia/cuda` base image version              |

```sh
docker build --build-arg BASALT_REF=v0.3.1 -t basalt:0.3.1 .
```

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

Basalt refuses an API key in its config file and takes it only on the command
line. The entrypoint reads it from `BASALT_API_KEY_FILE` and hands it to the
server in-process, so it never appears in the process's command line. If the
file is absent the server runs without a key and warns that it is open to the
network.

Arguments after the image name are passed through to `serve.server`:

```sh
docker run --gpus all ... basalt:0.3.2 --port 9000
```

The config format is documented upstream in
[docs/configuration](https://github.com/jesdga95/basalt/tree/master/docs/configuration).
`memlock` is unlimited and `shm_size` raised in `compose.yaml` because the
engine pins host memory for expert uploads.

## License

MIT for the files in this repository. Basalt itself is MIT-licensed by its
author; see the upstream repository and its `THIRD_PARTY_LICENSES`.
