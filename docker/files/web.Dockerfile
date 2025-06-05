# syntax = docker/dockerfile:1.15-labs@sha256:94edd5b349df43675bd6f542e2b9a24e7177432dec45fe3066bfcf2ab14c4355

#
# Assets build environment (with NodeJS)
#
# * Compile and bundle web assets
#
FROM timbru31/ruby-node:3.4-slim-22@sha256:dc8be0aae64ba696ae65b05e2a45989a64819e4465108c3fb488c0e1de0a9dca AS assets

ARG BRAND=xikolo
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE_DUMMY=true
ENV CPPFLAGS="-DPNG_ARM_NEON_OPT=0"

RUN mkdir --parents /app/
WORKDIR /app/

# Install dependencies for installing gems
RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet install \
    autoconf \
    build-essential \
    git \
    libcurl4 \
    libffi-dev \
    libidn11-dev \
    libpq-dev \
    libsodium23 \
    libtool \
    libyaml-dev \
    pax-utils \
    pkg-config \
    shared-mime-info \
    tzdata
EOF

COPY ./clients /app/clients
COPY ./gems /app/gems
COPY Gemfile Gemfile.lock /app/

RUN <<EOF
  gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
  bundle config set --local without 'development test integration'
  bundle install --jobs 4 --retry 3
EOF

COPY package.json yarn.lock .yarnrc.yml /app/

RUN <<EOF
  corepack yarn install
EOF

COPY --exclude=docker --exclude=services . /app/

RUN --mount=type=bind,target=/docker,source=/docker <<EOF
  make --jobs="$(/docker/bin/njobs)" all
EOF

#
# Application build environment
#
# * Install gems
# * Collect required native dependencies for gems
# * Clean up application directory
#
FROM ruby:3.4.3-slim@sha256:bf1ae63808063b7c3ba614d7e2e290011812ebffb7fd773f5ac4081d0c88538a AS build

ARG BRAND=xikolo
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE_DUMMY=true

RUN mkdir --parents /app/
WORKDIR /app/

# Install dependencies for installing gems
RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet install \
    build-essential \
    git \
    libcurl4 \
    libffi-dev \
    libidn11-dev \
    libpq-dev \
    libsodium23 \
    libyaml-dev \
    pax-utils \
    shared-mime-info \
    tzdata
EOF

COPY ./clients /app/clients
COPY ./gems /app/gems
COPY Gemfile Gemfile.lock /app/

RUN <<EOF
  gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
  bundle config set --local without 'development test integration'
  bundle install --jobs 4 --retry 3
EOF

# Scan gem files for linked native libaries, lookup the packages they
# are shipped with, and colled it list into a file so that only required
# packages can be installed in the runtime image below.
RUN <<EOF
  scanelf --recursive --needed --nobanner --format '%n#p' /usr/local/bundle/ \
    | tr ',' '\n' \
    | sort -u \
    | grep -v libruby.so* \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | tee /usr/local/bundle/packages
EOF

# Copy rest of the application (see .dockerignore too)
COPY . /app/
COPY --from=assets /app/public/assets/ /app/public/assets/

# Cleanup application directory
RUN <<EOF
  rm -rf /app/config/assets
  rm -rf /app/docker
  rm -rf /app/node_modules
  rm -rf /app/services
  rm -rf /app/tmp
EOF

#
# Runtime image
#
FROM docker.io/ruby:3.4.3-slim@sha256:bf1ae63808063b7c3ba614d7e2e290011812ebffb7fd773f5ac4081d0c88538a

ARG BRAND=xikolo
ARG BUILD_REF_NAME
ARG BUILD_COMMIT_SHA
ARG BUILD_COMMIT_SHORT_SHA
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production

ENV BUILD_REF_NAME=$BUILD_REF_NAME
ENV BUILD_COMMIT_SHA=$BUILD_COMMIT_SHA
ENV BUILD_COMMIT_SHORT_SHA=$BUILD_COMMIT_SHORT_SHA

RUN mkdir --parents /app/
WORKDIR /app/

# Add system user for running the app
RUN useradd --create-home --shell /bin/bash xikolo

# Install extra dependencies for runtime environment
RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet --no-install-recommends install \
    ffmpeg \
    libcurl4 \
    libsodium23 \
    shared-mime-info \
    tzdata \
    xz-utils
EOF

# Copy installed gems and config from `build` stage above
COPY --from=build /usr/local/bundle /usr/local/bundle

# Install required runtime packages for native dependencies
RUN <<EOF
  apt-get --yes --quiet update
  xargs apt-get install --yes < /usr/local/bundle/packages
EOF

# Copy application files from build stage
COPY --from=build /app/ /app/

# Ensure temp directory is writable
RUN <<EOF
  mkdir -p /app/tmp/
  chown 1000:1000 /app/tmp/
EOF

USER 1000:1000

EXPOSE 80/tcp

CMD [ "server" ]
ENTRYPOINT [ "/app/bin/entrypoint" ]
