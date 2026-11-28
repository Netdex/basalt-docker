# syntax=docker/dockerfile:1
ARG CUDA_VERSION=13.4.3

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu24.04 AS build
ARG BASALT_REF=v0.6.0
ARG BASALT_MODELS=all
RUN apt-get update \
 && apt-get install -y --no-install-recommends cmake g++ make git python3 \
 && rm -rf /var/lib/apt/lists/*
ADD --keep-git-dir=true https://github.com/jesdga95/basalt.git#${BASALT_REF} /src
WORKDIR /src
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release "-DBASALT_MODELS=${BASALT_MODELS}" \
 && cmake --build build -j"$(nproc)"
RUN python3 tools/package_release.py --tag "${BASALT_REF}" --platform linux-x64 --out /dist \
 && mkdir /opt/basalt \
 && tar -xzf /dist/basalt-*.tar.gz -C /opt/basalt --strip-components=1

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu24.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-venv \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/basalt /opt/basalt
# `basalt serve` runs the server with <install root>/.venv/bin/python.
RUN python3 -m venv /opt/basalt/.venv \
 && /opt/basalt/.venv/bin/pip install --no-cache-dir -r /opt/basalt/requirements.txt
COPY entrypoint.py /usr/local/lib/basalt-entrypoint.py
ENV PATH=/opt/basalt/bin:$PATH \
    PYTHONUNBUFFERED=1
WORKDIR /opt/basalt
EXPOSE 8080
ENTRYPOINT ["python3", "/usr/local/lib/basalt-entrypoint.py"]
