# frozen_string_literal: true

module AccountService
  class Engine < ::Rails::Engine
    isolate_namespace AccountService
    config.generators.api_only = true
  end
end
