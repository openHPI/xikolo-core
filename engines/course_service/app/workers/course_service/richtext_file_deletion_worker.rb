# frozen_string_literal: true

module CourseService
class RichtextFileDeletionWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(uri)
    return if Course.exists?(['description LIKE ?', "%#{uri}%"])
    return if Richtext.exists?(['text LIKE ?', "%#{uri}%"])

    Xikolo::S3.object(uri).delete
  end
end
end
