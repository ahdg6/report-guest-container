# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=quay.io/jupyter/scipy-notebook:2026-07-13@sha256:e760028814b48e503f8991e20f89ad7ba2725b34ca7d937b104584b78f11169f
FROM ${BASE_IMAGE}

ARG GUEST_REVISION=unknown
ARG JJ_VERSION=0.43.0
ARG JJ_SHA256_AMD64=59e5588583ac82b623239929368c65b90735931c0f26b5a16c1f04d5bb97643d
ARG JJ_SHA256_ARM64=289197b6bec60b4e57d47260624b617716f737eb02cdfd9155791b2576aa5862
ARG TARGETARCH

LABEL org.opencontainers.image.title="Pluxel Report Guest" \
  org.opencontainers.image.description="Offline document-analysis guest for the Pluxel Report Agent" \
  org.opencontainers.image.source="https://github.com/ahdg6/report-guest-container" \
  org.opencontainers.image.revision="${GUEST_REVISION}"

USER root

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    file \
    fonts-dejavu-core \
    jq \
    p7zip-full \
    pandoc \
    poppler-utils \
    ripgrep \
    tesseract-ocr \
    tesseract-ocr-chi-sim \
    tesseract-ocr-eng \
    unzip \
    zip \
  && rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
      amd64) jj_arch=x86_64; jj_sha256="${JJ_SHA256_AMD64}" ;; \
      arm64) jj_arch=aarch64; jj_sha256="${JJ_SHA256_ARM64}" ;; \
      *) echo "Unsupported TARGETARCH for jj: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
  && curl --fail --location --retry 3 \
    --output /tmp/jj.tar.gz \
    "https://github.com/jj-vcs/jj/releases/download/v${JJ_VERSION}/jj-v${JJ_VERSION}-${jj_arch}-unknown-linux-musl.tar.gz" \
  && echo "${jj_sha256}  /tmp/jj.tar.gz" | sha256sum --check - \
  && tar --extract --gzip --file /tmp/jj.tar.gz --directory /usr/local/bin ./jj \
  && chmod 0755 /usr/local/bin/jj \
  && rm /tmp/jj.tar.gz \
  && jj --version | grep --fixed-strings "jj ${JJ_VERSION}"

COPY requirements.txt /tmp/pluxel-guest-requirements.txt
RUN PIP_ROOT_USER_ACTION=ignore python -m pip install \
    --disable-pip-version-check \
    --no-cache-dir \
    --requirement /tmp/pluxel-guest-requirements.txt \
  && rm /tmp/pluxel-guest-requirements.txt

COPY --chmod=0444 jj-config.toml /etc/jj/config.toml
COPY --chmod=0444 jj-ignore /home/jovyan/.config/git/ignore
COPY --chmod=0444 JJ_AGENT_GUIDE.md guest-capabilities.json verify-guest.py /opt/pluxel/
RUN python -c "import fitz, docx, pptx, pyxlsb, odf, PIL, openpyxl, pandas" \
  && command -v file jq jj 7z pandoc pdfinfo pdftotext rg tesseract unzip zip >/dev/null \
  && jj --version | grep --fixed-strings "jj ${JJ_VERSION}"

USER ${NB_UID}
WORKDIR /home/jovyan
