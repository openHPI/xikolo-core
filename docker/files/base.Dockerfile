# syntax = docker/dockerfile:1.14

FROM docker.io/ruby:3.4.2-slim AS ruby-base

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
