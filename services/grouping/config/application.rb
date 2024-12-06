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
# require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'telegraf/rails'

module Xikolo::Grouping
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

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

    # Restify: Do not wrap hashes with object-like accessors
    Restify::Processors::Json.indifferent_access = false

    # Configure Telegraf event collection
    config.telegraf.tags = {application: 'grouping'}

    # The `TestGroup` model stores statistical metrics in a serialized
    # column, some of which are instances of +BigDecimal+. This
    # non-standard type needs to be whitelisted in order to be
    # serialized properly. See:
    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    #
    config.active_record.yaml_column_permitted_classes = [
      BigDecimal,
    ]
  end
end
