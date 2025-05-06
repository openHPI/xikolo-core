# syntax = docker/dockerfile:1.15@sha256:9857836c9ee4268391bb5b09f9f157f3c91bb15821bb77969642813b0d00518d

FROM nginx:1.27.5@sha256:c15da6c91de8d2f436196f3a768483ad32c258ed4e1beb3d367a27ed67253e66

RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet --no-install-recommends install ssl-cert
EOF

EXPOSE 80/tcp
EXPOSE 443/tcp
