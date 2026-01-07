# frozen_string_literal: true

require_relative 'markdown_service'
require_relative 'tracking_mail_interceptor'

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
