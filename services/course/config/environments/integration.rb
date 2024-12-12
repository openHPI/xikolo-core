# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests when running in CI.
  config.enable_reloading = ENV['CI'].blank?

  # Eager load code on boot. This eager loads most of Rails and your
  # application in memory, allowing both threaded web servers and those
  # relying on copy on write to perform better. Rake tasks automatically
  # ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Use local redis cache similar to production
  config.cache_store = :redis_cache_store, {
    url: 'redis://127.0.0.1/3',
    expires_in: 10.minutes,
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
