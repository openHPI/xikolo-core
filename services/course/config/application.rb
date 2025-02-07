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

# Require all patches before loading application
Dir[File.expand_path('../lib/patch/*.rb', __dir__)].each {|f| require f }

require 'telegraf/rails'

module Xikolo::CourseService
  class Application < Rails::Application
    include Xikolo::Common::Secrets

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks patch])

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

    config.i18n.available_locales = %i[cn de en es fr nl pt-BR ru uk]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = %i[en]

    ActiveSupport::JSON::Encoding.time_precision = 0

    # Configure Telegraf event collection
    config.telegraf.connect = ENV.fetch('TELEGRAF_CONNECT', nil)
    config.telegraf.tags = {application: 'course'}

    # Our paper trail setup uses YAML serialization into a text column,
    # and, in newer Rails and PT versions, the involved serializers use
    # `YAML.safe_load`. Therefore, several classes must be explicitly
    # whitelist, or deserialization will fail.
    #
    # PT recommends to migrate to JSON with jsonb columns:
    # https://github.com/paper-trail-gem/paper_trail/blob/v13.0.0/README.md#convert-existing-yaml-data-to-json
    #
    config.active_record.use_yaml_unsafe_load = false
    config.active_record.yaml_column_permitted_classes = [
      ActiveRecord::Type::Time::Value,
      ActiveSupport::TimeWithZone,
      ActiveSupport::TimeZone,
      BigDecimal,
      Date,
      Symbol,
      Time,
    ]
  end
end
