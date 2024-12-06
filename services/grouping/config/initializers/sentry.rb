# frozen_string_literal: true

Sentry.init do |config|
  # Far too many exception when sidekiq workers are just reconnecting
  config.excluded_exceptions += %w[Redis::CannotConnectError RedisClient::CannotConnectError]

  # Do not send full list of gems with each event
  config.send_modules = false
end

Sentry.set_tags(
  site: Xikolo.site.to_s,
  brand: Xikolo.brand.to_s
)
