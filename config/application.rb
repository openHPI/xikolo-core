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
Bundler.require(*Rails.groups(assets: %w[development test integration]))

# Load other things
require 'ims/lti'
require 'digest/md5'

# Include the OAuth proxy object for LTI
require 'oauth/request_proxy/action_controller_request'

require 'telegraf/rails'

##
# Configure the brand from an environment variable.
#
# We do this here to ensure the brand is configured correctly before the
# initializers are run.
#
Xikolo.brand = ENV['BRAND'] if ENV.key?('BRAND')

module Xikolo
  module Web
    class Application < Rails::Application
      include Xikolo::Common::Secrets
      include Xikolo::Common::Nomad

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

      # Brands may also provide their own initializers with custom setup code.
      config.paths['config/initializers'] << "brand/#{Xikolo.brand}/initializers"

      # Auto and eager load API and its subdirectories.
      # Auto and eager load library code and brand-specific code.
      config.autoload_paths += %W[
        #{config.root}/api
        #{config.root}/lib
        #{config.root}/constraints
        #{config.root}/brand/#{Xikolo.brand}/lib
      ]
      config.eager_load_paths += %W[
        #{config.root}/api
        #{config.root}/lib
        #{config.root}/constraints
        #{config.root}/brand/#{Xikolo.brand}/lib
      ]

      # Prepend all log lines with the following tags.
      config.log_tags = [:request_id]

      # When eager-loading, load the GeoIP database once to save memory.
      require 'geo_ip/lookup'
      config.eager_load_namespaces << GeoIP

      # Queuing and mails
      config.solid_queue.supervisor_pidfile = Rails.root.join('tmp/pids/solid_queue_supervisor.pid')
      config.active_job.queue_adapter = :delayed
      config.action_mailer.deliver_later_queue_name = 'mails'
      config.action_mailer.default_url_options = {
        host: Xikolo.base_url.host,
        port: Xikolo.base_url.port,
        protocol: Xikolo.base_url.scheme,
      }

      config.i18n.available_locales = %i[de en]
      config.i18n.default_locale = :en
      config.i18n.fallbacks = %i[en]

      # Enable escaping HTML in JSON.
      config.active_support.escape_html_entities_in_json = true

      OAUTH_10_SUPPORT = true

      config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }

      # Define status codes for a few common exceptions. These will affect both
      # Rails' debugging middleware and responses from our own exceptions app.
      config.action_dispatch.rescue_responses['Status::NotFound'] = :not_found
      config.action_dispatch.rescue_responses['Restify::BadGateway'] = :bad_gateway
      config.action_dispatch.rescue_responses['Acfs::BadGateway'] = :bad_gateway
      config.action_dispatch.rescue_responses['Restify::ServiceUnavailable'] = :service_unavailable
      config.action_dispatch.rescue_responses['Acfs::ServiceUnavailable'] = :service_unavailable
      config.action_dispatch.rescue_responses['Restify::GatewayTimeout'] = :gateway_timeout
      config.action_dispatch.rescue_responses['Acfs::GatewayTimeout'] = :gateway_timeout

      config.max_document_size = 8.megabytes
      config.navigation = ActiveSupport::OrderedOptions.new

      config.middleware.use Rack::Attack

      require 'middleware/news_tracker'
      config.middleware.use Middleware::NewsTracker

      config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins '*.openhpi.de'
          resource '*', headers: :any, methods: [:post]
        end

        # External video players (e.g. Google Chromecast) need access to the
        # HLS playlists
        allow do
          origins '*'
          resource '/playlists/*', headers: :any, methods: [:get]
        end
      end

      # Configure Telegraf event collection
      config.telegraf.connect = ENV.fetch('TELEGRAF_CONNECT', nil)
      config.telegraf.tags = {application: 'web'}

      # Some of our models store data in YAML-serialized columns, some of which
      # may contain types that are not safe for YAML serialization. These
      # non-standard type needs to be listed here to be serialized properly.
      #
      # - +Gamification::Score+ stores a hash of IDs with symbol keys
      #
      # See https://discuss.rubyonrails.org/t/cve-2022-32224/81017
      #
      # ----
      #
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

      # Enable ActiveSupport notifications for all ViewComponents
      config.view_component.instrumentation_enabled = true
      config.view_component.use_deprecated_instrumentation_name = false

      # Configure lookup path for previews and add code sample to preview page.
      config.view_component.show_previews = false
      config.view_component.default_preview_layout = 'lookbook/default_preview'
      config.view_component.preview_paths << "#{Rails.root}/app/components/"
      config.lookbook.listen_paths = ["#{Rails.root}/app/components/"]
      config.lookbook.page_paths = ["#{Rails.root}/app/components/docs/"]
      config.lookbook.preview_embeds.panels = %w[notes source output]
      config.lookbook.page_options = {header: false}

      # Enable serving of images, stylesheets, and JavaScripts from an asset server.
      #
      # This option must be set in an `after_initialize` block because the
      # Xikolo config will not be loaded before.
      config.after_initialize do
        ActionController::Base.asset_host = Xikolo.config.asset_host.presence || ENV.fetch('ASSET_HOST', nil)
      end
    end
  end
end
