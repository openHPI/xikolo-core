# frozen_string_literal: true

Sentry.init do |config|
  # Include /api as in-app stacktrace lines.
  #
  # Ignore lib/acfs_rails_cache.rb and config/initializers/acfs.rb.
  # They define generic wrappers that would otherwise be the summary for
  # the "primary" line for many exceptions.
  config.app_dirs_pattern = %r{(api|app|config(?!/initializers/acfs.rb$)|lib(?!/acfs_rails_cache.rb$))}

  # Ignore a few common exceptions that sometimes bubble up to Rails' error
  # handling middleware. These are expected to occur and have dedicated
  # handler logic in our exceptions app.
  config.excluded_exceptions += %w[
    Acfs::BadGateway
    Acfs::GatewayTimeout
    Acfs::ServiceUnavailable
    Status::NotFound
    Restify::BadGateway
    Restify::GatewayTimeout
    Restify::ServiceUnavailable
    ApplicationJob::ExpectedRetry
  ]

  # Far too many exception when sidekiq workers are just reconnecting
  config.excluded_exceptions += %w[Redis::CannotConnectError RedisClient::CannotConnectError]

  config.release = ENV['DEB_VERSION'] if ENV['DEB_VERSION']

  # Do not send full list of gems with each event
  config.send_modules = false
end

Sentry.set_tags(
  site: Xikolo.site.to_s,
  brand: Xikolo.brand.to_s
)

# Add Mnemosyne's trace ID to the current Sentry context.
# We do this in a middleware, as doing in a controller could change the ID when
# touching multiple controllers (e.g. error app) in a request.
class AnnotateSentryErrorsForMnemosyne
  def initialize(app)
    @app = app
  end

  def call(env)
    if (trace = Mnemosyne::Instrumenter.current_trace)
      Sentry.get_current_scope.set_context('mnemosyne', {trace_id: trace.uuid})
    end

    @app.call(env)
  end
end

Rails.application.config.middleware.use AnnotateSentryErrorsForMnemosyne
