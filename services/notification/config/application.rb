# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
# require 'action_cable/engine'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'telegraf/rails'

##
# Configure the brand from an environment variable.
#
# We do this here to ensure the brand is configured correctly before the
# initializers are run.
#
Xikolo.brand = ENV['BRAND'] if ENV.key?('BRAND')

module Xikolo::NotificationService
  class Application < Rails::Application
    include Xikolo::Common::Secrets

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Prepend all log lines with the following tags.
    config.log_tags = [:request_id]

    # Auto and eager load library code
    config.autoload_paths += %W[#{config.root}/lib]
    config.eager_load_paths += %W[#{config.root}/lib]

    # This service is an API-only services and must not verify
    # CSRF tokens on POST requests.
    config.action_controller.default_protect_from_forgery = false

    config.i18n.available_locales = %i[cn de en es fr nl pt-BR ru uk zh]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = %i[en]

    # Configure Telegraf event collection
    config.telegraf.tags = {application: 'notification'}

    initializer 'configure-mailer' do
      Premailer::Rails.config.merge!(generate_text_part: false)
    end
  end
end
