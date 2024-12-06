# frozen_string_literal: true

class SubmissionFileDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      size:,
      name:,
      user_id:,
      mime_type:,
      download_url: Xikolo::S3.object(storage_uri).presigned_url(:get, expires_in: 3600),
      created_at:,
    }.as_json(opts)
  end
end
