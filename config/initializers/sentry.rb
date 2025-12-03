# frozen_string_literal: true

Sentry.init do |config|
  # Skip health check transactions
  config.before_send_transaction = lambda do |event, _hint|
    unless ['/ping', '/up', '/system_info'].include?(event.transaction)
      event
    end
  end

  # The default sampling rate for Sentry transactions. Unless other
  # rules apply below, sample all requests by default.
  #
  # Collect profiles are transactions that are sampled.
  config.traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', '1.0').to_f
  config.profiler_class = Sentry::Vernier::Profiler
  config.profiles_sample_rate = 1.0
  config.enable_logs = false
  config.enabled_patches = [:logger]
end

Sentry.set_tags(
  site: Xikolo.site.to_s,
  brand: Xikolo.brand.to_s
)
