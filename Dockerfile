# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t bun_app .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name bun_app bun_app

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=4.0.10
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips ffmpeg postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips libyaml-dev pkg-config unzip libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
ARG BUN_VERSION=1.3.6
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# Install application gems
COPY vendor/* ./vendor/
COPY gems ./gems
COPY engines ./engines
COPY clients ./clients
COPY Gemfile Gemfile.lock ./

RUN bundle install # && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
    bundle exec bootsnap precompile -j 1 --gemfile

# Install node modules
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times.
# -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


RUN rm -rf node_modules


# Final stage for app image
FROM base

ARG BUILD_REF_NAME
ARG BUILD_COMMIT_SHA
ARG BUILD_COMMIT_SHORT_SHA
ARG RELEASE_NUMBER

ENV BUILD_REF_NAME=$BUILD_REF_NAME
ENV BUILD_COMMIT_SHA=$BUILD_COMMIT_SHA
ENV BUILD_COMMIT_SHORT_SHA=$BUILD_COMMIT_SHORT_SHA
ENV RELEASE_NUMBER=$RELEASE_NUMBER

LABEL org.opencontainers.image.title="xikolo-web"
LABEL org.opencontainers.image.vendor="Hasso Plattner Institute for Digital Engineering gGmbH"
LABEL org.opencontainers.image.ref.name=$BUILD_REF_NAME
LABEL org.opencontainers.image.revision=$BUILD_COMMIT_SHA
LABEL org.opencontainers.image.version=$BUILD_REF_NAME

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# Copy built artifacts: gems, application
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

EXPOSE 80
CMD ["server"]
ENTRYPOINT [ "/rails/bin/entrypoint" ]
