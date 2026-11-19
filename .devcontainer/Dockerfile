# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=4.0.9@sha256:4f9a4f82ce15d03b8ef96631d42334ee8cb0f88bbca85829db339b8a92a32356
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# Ensure binding is always 0.0.0.0
# Binds the server to all IP addresses of the container, so it can be accessed from outside the container.
ENV BINDING="0.0.0.0"

RUN sudo apt-get update && sudo apt-get install --yes \
  build-essential \
  coreutils \
  curl \
  ffmpeg \
  git \
  libcurl4 \
  libffi-dev \
  libgirepository1.0-dev \
  libpq-dev \
  libsodium23 \
  libyaml-dev \
  libvips \
  python3 \
  socat \
  shared-mime-info \
  tzdata \
  unzip
