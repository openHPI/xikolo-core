# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Conditional load "bootsnap" gem. This gem can speed up application boot by
# caching parsed ruby instruction sequences, precomputing and caching include
# and load paths as well as caching loaded YAML configuration files.
#
# Due to bootsnap's assumptions about the environment, e.g. always running as the
# same, regular user, there are few issues with running bootsnap in production
# environments then integration more with the system, e.g. running as native
# system services, having maintenance task running as different users or when
# the running user does not own the source files.
#
# Therefore, bootsnap should only be available in the development group in the
# Gemfile and can only be loaded when running in the development Rails
# environment. This lets local servers run faster, while production runs safer.
begin
  require 'bootsnap/setup'
rescue LoadError
  # Do nothing
end
