# syntax = docker/dockerfile:1.12@sha256:db1ff77fb637a5955317c7a3a62540196396d565f3dd5742e76dddbb6d75c4c5

FROM nginx:1.27.3@sha256:0c86dddac19f2ce4fd716ac58c0fd87bf69bfd4edabfd6971fb885bafd12a00b

RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet --no-install-recommends install ssl-cert
EOF

EXPOSE 80/tcp
EXPOSE 443/tcp
