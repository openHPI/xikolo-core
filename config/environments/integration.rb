# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = true
  config.eager_load = true

  # Configure public file server for tests with Cache-Control for performance
  config.public_file_server.enabled = !ENV.key?('DISABLE_FILE_SERVER')
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}",
  }

  # Full error reports are disabled
  config.consider_all_requests_local = false

  # Render exception templates
  config.action_dispatch.show_exceptions = true

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  begin
    TCPSocket.new('127.0.0.1', '2525').close
    config.action_mailer.delivery_method = :smtp
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    config.action_mailer.delivery_method = :test
  end

  config.action_mailer.smtp_settings = {
    address: '127.0.0.1',
    port: 2525,
  }

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  # Cache
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, {
    url: 'redis://127.0.0.1/3',
    expires_in: 10.minutes,
  }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr
end
