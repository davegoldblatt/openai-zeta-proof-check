# Checking environment for the openai/math QuasiRiemannHypothesis comparator challenge.
# Toolchain and checker binaries are root-owned so that code run later by the
# unprivileged `verifier` user cannot modify them.
FROM public.ecr.aws/docker/library/ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git curl ca-certificates zstd xz-utils procps time file python3 \
 && rm -rf /var/lib/apt/lists/*

# Lean toolchain (pinned by lean/lean-toolchain) via elan, system-wide.
ENV ELAN_HOME=/opt/elan
ARG ELAN_VERSION=v4.2.4
RUN curl -sSfL "https://raw.githubusercontent.com/leanprover/elan/${ELAN_VERSION}/elan-init.sh" -o /tmp/elan-init.sh \
 && sh /tmp/elan-init.sh -y --no-modify-path --default-toolchain leanprover/lean4:v4.34.1 \
 && rm /tmp/elan-init.sh \
 && /opt/elan/bin/elan toolchain install leanprover/lean4:v4.34.1 \
 && ls -la /opt/elan/toolchains/ \
 && /opt/elan/toolchains/leanprover--lean4---v4.34.1/bin/lean --version \
 && /opt/elan/toolchains/leanprover--lean4---v4.34.1/bin/lake --version \
 && chmod -R a+rX,go-w /opt/elan
# Use the toolchain binaries directly (not elan proxies), so nothing can switch toolchains.
ENV LEAN_BIN=/opt/elan/toolchains/leanprover--lean4---v4.34.1/bin
ENV PATH=/opt/elan/toolchains/leanprover--lean4---v4.34.1/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Go, only for building landrun.
ARG GO_TARBALL=go1.27.1.linux-arm64.tar.gz
ARG GO_SHA256=3450b45a3f9ee8568792736a5c5e70a1f2e9b36c35a8f74958c03e51d7d92bec
RUN curl -sSfL "https://go.dev/dl/${GO_TARBALL}" -o /tmp/go.tgz \
 && echo "${GO_SHA256}  /tmp/go.tgz" | sha256sum -c - \
 && tar -C /usr/local -xzf /tmp/go.tgz \
 && rm /tmp/go.tgz

RUN useradd -m -u 1001 -s /bin/bash builder \
 && useradd -m -u 1002 -s /bin/bash verifier \
 && install -d -o verifier -g verifier /home/verifier/work

USER builder
WORKDIR /home/builder

# landrun, main branch.
ARG LANDRUN_COMMIT=811cfff51ceaf3d9843708aa6d22e9b84ccac8b4
RUN git clone https://github.com/Zouuup/landrun.git \
 && cd landrun \
 && git checkout --detach "${LANDRUN_COMMIT}" \
 && test "$(git rev-parse HEAD)" = "${LANDRUN_COMMIT}" \
 && test "$(git rev-parse origin/main)" = "${LANDRUN_COMMIT}" \
 && GOPATH=/home/builder/go GOCACHE=/home/builder/.cache/go-build GOFLAGS=-mod=readonly go build -o landrun ./cmd/landrun

# comparator + lean4export at their v4.34.0 tags: the last commits on the v4.34 toolchain
# (later commits only bump to v4.35 release candidates). Built with Lean v4.34.1 so that
# lean4export reads this project's .olean files.
ARG COMPARATOR_COMMIT=d03acab154d269c06e60e4de7e4cc85deebff94b
ARG LEAN4EXPORT_COMMIT=076e8e57707e813375e8f9da8bf989799ace9680
RUN git clone https://github.com/leanprover/comparator.git \
 && cd comparator \
 && git checkout --detach "${COMPARATOR_COMMIT}" \
 && test "$(git rev-parse HEAD)" = "${COMPARATOR_COMMIT}" \
 && test "$(git rev-parse 'v4.34.0^{commit}')" = "${COMPARATOR_COMMIT}" \
 && grep -q "\"rev\": \"${LEAN4EXPORT_COMMIT}\"" lake-manifest.json \
 && echo "leanprover/lean4:v4.34.1" > lean-toolchain \
 && lake build lean4export comparator \
 && test "$(git -C .lake/packages/lean4export rev-parse HEAD)" = "${LEAN4EXPORT_COMMIT}"

USER root
RUN install -m 0755 -o root -g root /home/builder/landrun/landrun /usr/local/bin/landrun \
 && install -m 0755 -o root -g root /home/builder/comparator/.lake/build/bin/comparator /usr/local/bin/comparator \
 && install -m 0755 -o root -g root /home/builder/comparator/.lake/packages/lean4export/.lake/build/bin/lean4export /usr/local/bin/lean4export

USER verifier
WORKDIR /home/verifier/work
