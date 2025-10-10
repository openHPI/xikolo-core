# frozen_string_literal: true

module NotificationService
  class Engine < ::Rails::Engine
    isolate_namespace NotificationService
    config.generators.api_only = true
  end
end
