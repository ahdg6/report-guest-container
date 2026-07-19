# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=quay.io/jupyter/scipy-notebook:2026-07-13@sha256:e760028814b48e503f8991e20f89ad7ba2725b34ca7d937b104584b78f11169f
FROM ${BASE_IMAGE}

ARG GUEST_REVISION=unknown

LABEL org.opencontainers.image.title="Pluxel Report Guest" \
  org.opencontainers.image.description="Offline document-analysis guest for the Pluxel Report Agent" \
  org.opencontainers.image.source="https://github.com/ahdg6/report-guest-container" \
  org.opencontainers.image.revision="${GUEST_REVISION}"

USER root

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
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

COPY requirements.txt /tmp/pluxel-guest-requirements.txt
RUN PIP_ROOT_USER_ACTION=ignore python -m pip install \
    --disable-pip-version-check \
    --no-cache-dir \
    --requirement /tmp/pluxel-guest-requirements.txt \
  && rm /tmp/pluxel-guest-requirements.txt

COPY guest-capabilities.json verify-guest.py /opt/pluxel/
RUN chmod 0444 /opt/pluxel/guest-capabilities.json /opt/pluxel/verify-guest.py \
  && python -c "import fitz, docx, pptx, pyxlsb, odf, PIL, openpyxl, pandas" \
  && command -v file jq 7z pandoc pdfinfo pdftotext rg tesseract unzip zip >/dev/null

USER ${NB_UID}
WORKDIR /home/jovyan
