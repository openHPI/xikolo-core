# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.4
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
  librsvg2-dev \
  libsodium23 \
  libyaml-dev \
  pkg-config \
  python3 \
  socat \
  shared-mime-info \
  tzdata \
  unzip
