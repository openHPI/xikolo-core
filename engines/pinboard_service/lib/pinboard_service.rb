# frozen_string_literal: true

module PinboardService
  class Engine < ::Rails::Engine
    isolate_namespace PinboardService
    config.generators.api_only = true
  end
end
