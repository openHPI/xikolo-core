# frozen_string_literal: true

require 'active_support/parameter_filter'

Sentry.init do |config|
  # We trigger intentional retries using this class, so no need to report them.
  config.excluded_exceptions += %w[ApplicationJob::Retry]

  # Far too many exception when sidekiq workers are just reconnecting
  config.excluded_exceptions += %w[Redis::CannotConnectError RedisClient::CannotConnectError]

  # Do not send full list of gems with each event
  config.send_modules = false

  # Set sampling rates to 1.0 to capture 100% of transactions and
  # profiles for performance monitoring.
  config.traces_sample_rate = 1.0
  config.profiles_sample_rate = 1.0

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    # use Rails' parameter filter to sanitize the event
    filter.filter(event.to_hash)
  end
end

Sentry.set_tags(
  site: Xikolo.site.to_s,
  brand: Xikolo.brand.to_s
)
