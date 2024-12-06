# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.eager_load = true
  config.cache_classes = true

  # Cache
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, {
    url: 'redis://127.0.0.1/3',
    expires_in: 10.minutes,
  }

  # Full error reports are disabled
  config.consider_all_requests_local = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
end
