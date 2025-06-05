# syntax = docker/dockerfile:1.15@sha256:9857836c9ee4268391bb5b09f9f157f3c91bb15821bb77969642813b0d00518d

FROM nginx:1.27.5@sha256:fb39280b7b9eba5727c884a3c7810002e69e8f961cc373b89c92f14961d903a0

RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet --no-install-recommends install ssl-cert
EOF

EXPOSE 80/tcp
EXPOSE 443/tcp
