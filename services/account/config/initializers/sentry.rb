# frozen_string_literal: true

Sentry.init do |config|
  # We trigger intentional retries using this class, so no need to report them.
  config.excluded_exceptions += %w[ApplicationJob::Retry]

  # Far too many exception when sidekiq workers are just reconnecting
  config.excluded_exceptions += %w[Redis::CannotConnectError RedisClient::CannotConnectError]

  # Do not send full list of gems with each event
  config.send_modules = false
end

Sentry.set_tags(
  site: Xikolo.site.to_s,
  brand: Xikolo.brand.to_s
)
