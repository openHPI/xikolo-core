# syntax = docker/dockerfile:1.14@sha256:4c68376a702446fc3c79af22de146a148bc3367e73c25a5803d453b6b3f722fb

FROM docker.io/ruby:3.4.3-slim@sha256:fcbc3577e23cb188d769e496e7afe639b9946a2bf47c3deac7a38ad58187f6a9 AS build

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

COPY ./gems /app/gems
COPY services/account/Gemfile* /app/

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
COPY services/account/ /app/

# Cleanup application directory
RUN <<EOF
  # rm -r ...
EOF


#
# Runtime image
#
FROM docker.io/ruby:3.4.3-slim@sha256:fcbc3577e23cb188d769e496e7afe639b9946a2bf47c3deac7a38ad58187f6a9

ARG BRAND=xikolo
ARG BUILD_REF_NAME
ARG BUILD_COMMIT_SHA
ARG BUILD_COMMIT_SHORT_SHA
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE_DUMMY=true

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
