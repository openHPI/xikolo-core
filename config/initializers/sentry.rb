# frozen_string_literal: true

require 'active_support/parameter_filter'

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

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    # use Rails' parameter filter to sanitize the event
    filter.filter(event.to_hash)
  end

  # The default sampling rate for Sentry transactions. Unless other
  # rules apply below, sample all requests by default.
  #
  # Collect profiles are transactions that are sampled.
  config.traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', '1.0').to_f
  config.profiles_sample_rate = 1.0

  config.traces_sampler = lambda do |ctx|
    # If this is the continuation of a trace, just use that decision
    # (rate controlled by the caller).
    unless ctx[:parent_sampled].nil?
      next ctx[:parent_sampled]
    end

    # `transaction_context` is the transaction object in hash form. Keep
    # in mind that sampling happens right after the transaction is
    # initialized for example, at the beginning of the request.
    transaction_context = ctx[:transaction_context]

    # `transaction_context` helps you sample transactions with more
    # sophistication. For example, you can provide different sample
    # rates based on the operation or name.
    op = transaction_context[:op]
    transaction_name = transaction_context[:name]

    case op
      when 'http.server'
        # For Rails applications, the transaction name would be the
        # request's path (env["PATH_INFO"]) instead of
        # "Controller#action".
        case transaction_name
          when %r{^/(up|ping|system_info)}
            return 0.0 # Ignore health check requests
        end
    end

    config.traces_sample_rate
  end
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
