# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require 'active_storage/engine'
require 'action_controller/railtie'
# require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
# require 'action_cable/engine'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'telegraf/rails'

# Configure the brand from an environment variable.
#
# We do this here to ensure the brand is configured correctly before the
# initializers are run.
#
Xikolo.brand = ENV['BRAND'] if ENV.key?('BRAND')

module Xikolo::Account
  class Application < Rails::Application
    include Xikolo::Common::Secrets

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories
    # that do not contain `.rb` files, or that should not be reloaded or
    # eager loaded. Common ones are `templates`, `generators`, or
    # `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.paths['config/initializers'] << "brand/#{Xikolo.brand}/initializers"

    config.paths.add 'lib', load_path: true, eager_load: true
    config.paths.add "brand/#{Xikolo.brand}/lib", load_path: true, eager_load: true

    config.session_store :cookie_store, key: '_xaccount'

    config.active_support.time_precision = 0

    # Prepend all log lines with the following tags.
    config.log_tags = [:request_id]

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Configure Telegraf event collection
    config.telegraf.connect = ENV.fetch('TELEGRAF_CONNECT', nil)
    config.telegraf.tags = {application: 'account'}
  end
end
