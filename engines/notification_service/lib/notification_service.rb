# frozen_string_literal: true

module NotificationService
  class Engine < ::Rails::Engine
    isolate_namespace NotificationService
    config.generators.api_only = true

    initializer 'notification_service.assets.precompile' do |app|
      app.config.assets.paths << root.join('app/assets').to_s
      app.config.assets.precompile += %w[
        notification_service/foundation.css
        notification_service/old.css
      ]
    end
  end
end
