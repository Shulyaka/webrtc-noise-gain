FROM quay.io/pypa/manylinux_2_28_x86_64 as build-amd64

FROM quay.io/pypa/manylinux_2_28_aarch64 as build-arm64

ARG TARGETARCH
ARG TARGETVARIANT
FROM build-${TARGETARCH}${TARGETVARIANT} as build
ARG TARGETARCH
ARG TARGETVARIANT

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /build

COPY ./ ./
RUN for version in 7 8 9 10 11; do \
    "python3.${version}" -m venv ".venv_${version}" && \
    source ".venv_${version}"/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install --upgrade build wheel && \
    python3 -m build --wheel; \
    done

WORKDIR /test
COPY ./tests/ ./tests/
RUN for version in 7 8 9 10 11; do \
    "python3.${version}" -m venv ".venv_${version}" && \
    source ".venv_${version}"/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install --upgrade wheel pytest && \
    pip3 install --no-index webrtc-noise-gain -f /build/dist/ && \
    pytest tests; \
    done

WORKDIR /build
RUN find dist -name '*.whl' | xargs auditwheel repair

# -----------------------------------------------------------------------------

FROM scratch
ARG TARGETARCH
ARG TARGETVARIANT

COPY --from=build /build/wheelhouse/ ./
