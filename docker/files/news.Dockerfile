# syntax = docker/dockerfile:1.13@sha256:426b85b823c113372f766a963f68cfd9cd4878e1bcc0fda58779127ee98a28eb

FROM docker.io/ruby:3.3.6-slim@sha256:b210597cc7d05e19edf9c8e7935dcf1554886905dcdad0475cfe63a654147f7a AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production

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
    pax-utils \
    shared-mime-info \
    tzdata
EOF

COPY ./gems /app/gems
COPY services/news/Gemfile* /app/

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
COPY services/news/ /app/

# Cleanup application directory
RUN <<EOF
  # rm -r ...
EOF


#
# Runtime image
#
FROM docker.io/ruby:3.3.6-slim@sha256:b210597cc7d05e19edf9c8e7935dcf1554886905dcdad0475cfe63a654147f7a

ARG BRAND=xikolo
ARG BUILD_REF_NAME
ARG BUILD_COMMIT_SHA
ARG BUILD_COMMIT_SHORT_SHA
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=1

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
    curl \
    git \
    libcurl4 \
    libsodium23 \
    nginx \
    shared-mime-info \
    tzdata \
    xz-utils
EOF

COPY docker/rootfs/news/ /
COPY docker/bin/ /docker/bin
RUN /docker/bin/install-s6-overlay

# Copy installed gems and config from `build` stage above
COPY --from=build /usr/local/bundle /usr/local/bundle

# Install required runtime packages for native dependencies
RUN <<EOF
  apt-get --yes --quiet update
  xargs apt-get install --yes < /usr/local/bundle/packages
EOF

# Copy application files from build stage
COPY --from=build /app/ /app/

EXPOSE 80/tcp

CMD [ "server" ]
ENTRYPOINT [ "/init", "with-contenv", "/app/bin/entrypoint" ]
