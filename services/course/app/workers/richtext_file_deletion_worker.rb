# frozen_string_literal: true

class RichtextFileDeletionWorker
  include Sidekiq::Job

  def perform(uri)
    return if Course.exists?(['description LIKE ?', "%#{uri}%"])
    return if Richtext.exists?(['text LIKE ?', "%#{uri}%"])

    Xikolo::S3.object(uri).delete
  end
end
