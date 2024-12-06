# frozen_string_literal: true

##
# Report all unhandled exceptions in Msgr consumers to Sentry.
#
module MsgrSentryIntegration
  def dispatch(*)
    Sentry.with_scope do
      super
    rescue Sentry::Error
      raise # Don't capture Sentry errors
    rescue Exception => e # rubocop:disable Lint/RescueException
      Sentry.capture_exception(e)
      raise
    end
  end
end

Msgr::Consumer.prepend MsgrSentryIntegration
