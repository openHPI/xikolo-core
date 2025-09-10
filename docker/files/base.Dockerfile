# syntax = docker/dockerfile:1.18@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

FROM docker.io/ruby:3.4.4-slim@sha256:5d7149ee7eda2420d1b2bc3af78798de9eac3098e910c44a3ddd93da2a4130ca AS ruby-base

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
