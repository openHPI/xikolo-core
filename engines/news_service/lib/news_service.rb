# frozen_string_literal: true

module NewsService
  class Engine < ::Rails::Engine
    isolate_namespace NewsService
    config.generators.api_only = true

    initializer 'news_service.assets.precompile' do |app|
      app.config.assets.paths << root.join('app/assets').to_s
      app.config.assets.precompile += %w[
        news_service/foundation.css
      ]
    end
  end
end
