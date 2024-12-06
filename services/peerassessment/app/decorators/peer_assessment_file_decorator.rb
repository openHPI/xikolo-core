# frozen_string_literal: true

class PeerAssessmentFileDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      size:,
      name:,
      user_id:,
      mime_type:,
      download_url: Xikolo::S3.object(storage_uri).public_url,
      created_at:,
    }.as_json(opts)
  end
end
