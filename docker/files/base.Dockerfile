# syntax = docker/dockerfile:1.14@sha256:4c68376a702446fc3c79af22de146a148bc3367e73c25a5803d453b6b3f722fb

FROM docker.io/ruby:3.4.2-slim@sha256:342bfeb04d3660045ceba063197d22baafec6b163f019714ddf8fc83c59aabee AS ruby-base

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

RUN --mount=type=bind,source=packages.txt,target=packages.txt <<-EOF
  apt-get update
  apt-get --option Dpkg::Use-Pty=0 install --yes --no-install-recommends $(cat packages.txt)
EOF


FROM ruby-base AS ruby-base-node

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

RUN <<-EOF
  curl -fL https://deb.nodesource.com/setup_22.x | bash
  apt-get install --yes --no-install-recommends nodejs
  corepack enable
EOF


FROM ruby-base-node AS ruby-base-chrome

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

RUN <<-EOF
  curl -fL --output chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  apt-get install --yes --no-install-recommends ./chrome.deb
EOF
