# frozen_string_literal: true

module AccountService
class FileDeletionJob < ApplicationJob # rubocop:disable Layout/IndentationWidth
  queue_as :default

  def perform(uri)
    Xikolo::S3.object(uri).delete
  rescue Aws::S3::Errors::ServiceError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
  end
end
end
