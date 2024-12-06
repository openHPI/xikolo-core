# frozen_string_literal: true

require 'yaml'

module Xikolo
  module Sidekiq
    require 'xikolo/sidekiq/railtie' if defined? Rails
  end
end
