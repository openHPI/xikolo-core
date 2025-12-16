# frozen_string_literal: true

module CourseService
class FileDeletionWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(uri)
    Xikolo::S3.object(uri).delete
  rescue URI::InvalidURIError
    # No valid URI, no deletion
  end
end
end
