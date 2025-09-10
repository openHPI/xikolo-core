# syntax = docker/dockerfile:1.18@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

FROM nginx:1.29.1@sha256:33e0bbc7ca9ecf108140af6288c7c9d1ecc77548cbfd3952fd8466a75edefe57

RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet --no-install-recommends install ssl-cert
EOF

EXPOSE 80/tcp
EXPOSE 443/tcp
