# frozen_string_literal: true

module NewsService
  class Engine < ::Rails::Engine
    isolate_namespace NewsService
    config.generators.api_only = true
  end
end
