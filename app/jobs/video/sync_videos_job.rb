# frozen_string_literal: true

module Video
  class SyncVideosJob < LongRunningApplicationJob
    queue_with_priority :eventual

    # When the authentication with the video provider fails, this
    # - often can be considered a configuration error (invalid token or
    #   expired account) and the job shall not be retried,
    # - or is a temporary issue, which is covered by retries via cron.
    #
    # The (domain-specific) error is reported to the monitoring systems so
    # it will not go unnoticed.
    discard_on ::Video::Provider::AuthenticationFailed,
      ::Video::Provider::AccountInactive do |_job, e|
      ::Sentry.capture_exception(e)
    end

    # Since this job is scheduled via cron anyway, the number of retries can
    # be reduced.
    def max_attempts
      3
    end

    def perform(provider: nil, full: false)
      return Provider.find(provider).sync(full:) if provider

      Provider.ids.each do |id|
        self.class.perform_later(provider: id, full:)
      end
    rescue ActiveRecord::RecordNotFound => e
      ::Sentry.capture_exception(e)
    end
  end
end
