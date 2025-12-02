# frozen_string_literal: true

class S3FileDeletionJob < ApplicationJob
  queue_as :default
  queue_with_priority :eventual

  def perform(uri)
    Xikolo::S3.object(uri).delete if uri.present?
  rescue URI::InvalidURIError, ArgumentError
    # No valid URI, no deletion
  rescue Aws::S3::Errors::ServiceError => e
    ::Sentry.capture_exception(e)
  end
end
