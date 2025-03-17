# frozen_string_literal: true

require 'active_support/parameter_filter'

Sentry.init do |config|
  # We trigger intentional retries using this class, so no need to report them.
  config.excluded_exceptions += %w[ApplicationJob::Retry]

  # Far too many exception when sidekiq workers are just reconnecting
  config.excluded_exceptions += %w[Redis::CannotConnectError RedisClient::CannotConnectError]

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
