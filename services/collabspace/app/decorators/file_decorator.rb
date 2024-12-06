# frozen_string_literal: true

class FileDecorator < Draper::Decorator
  delegate_all

  def as_json(*)
    {
      id:,
      title:,
      original_filename: file_data.original_filename,
      size: file_data.size,
      creator_id:,
      created_at: file_data.created_at,
      blob_url: Xikolo::S3.object(file_data.blob_uri).presigned_url(
        :get, expires_in: 3.hours.to_i
      ),
      url: h.file_url(id),
    }
  end
end
