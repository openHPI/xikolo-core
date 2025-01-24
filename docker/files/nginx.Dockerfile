# syntax = docker/dockerfile:1.13@sha256:426b85b823c113372f766a963f68cfd9cd4878e1bcc0fda58779127ee98a28eb

FROM nginx:1.27.3@sha256:0a399eb16751829e1af26fea27b20c3ec28d7ab1fb72182879dcae1cca21206a

RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet --no-install-recommends install ssl-cert
EOF

EXPOSE 80/tcp
EXPOSE 443/tcp
