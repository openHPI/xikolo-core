# frozen_string_literal: true

module Xikolo::Config
  class Railtie < ::Rails::Railtie
    config.before_configuration do
      # Load service-specific configuration defaults
      Xikolo::Config.add_config_location Rails.root.join('app/xikolo.yml')

      # Load local configuration (local to the machine)
      #
      # Do not load global configuration files in the test environments,
      # as we want to be able to assume the standard config when running
      # tests.
      if %w[test integration].exclude?(Rails.env) && ENV.key?('HOME')
        Xikolo::Config.add_config_location ::File.expand_path('~/.xikolo.yml')
      end

      # Load project-specific configuration
      Xikolo::Config.add_config_location Rails.root.join('config/xikolo.yml')

      # Load local template files in Nomad/container deployments
      Xikolo::Config.add_config_location '/local/xikolo.yml'
      Xikolo::Config.add_config_location '/local/config/xikolo.yml'

      # Load environment-specific configuration
      Xikolo::Config.add_config_location File.expand_path("../../config.#{Rails.env}.yml", __FILE__)
      if ENV.key?('HOME')
        Xikolo::Config.add_config_location ::File.expand_path("~/.xikolo.#{Rails.env}.yml")
      end
      Xikolo::Config.add_config_location Rails.root.join("config/xikolo.#{Rails.env}.yml")
    end
  end
end
