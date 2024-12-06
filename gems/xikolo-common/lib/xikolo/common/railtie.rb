# frozen_string_literal: true

module Xikolo::Common
  class Railtie < ::Rails::Railtie
    initializer :common_services do |app|
      services = app.config_for(:services)&.with_indifferent_access
      services = services&.fetch('services', {}).presence || {}

      if (file = Rails.root.join("config/services.#{Rails.env}.yml")).file?
        services.merge! YAML.load(ERB.new(file.read).result).fetch(Rails.env, {}).fetch('services', {})
      end

      # Register services with Restify wrapper
      services.each do |service, location|
        Xikolo::Common::API.assign service, location
      end

      # Register services with Acfs, if available
      if defined? Acfs
        Acfs.configure do |config|
          services.each do |service, location|
            config.locate service, location
          end
        end
      end
    end
  end
end
