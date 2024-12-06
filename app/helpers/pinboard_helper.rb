# frozen_string_literal: true

module PinboardHelper
  def questions_per_page
    25 # TODO: adjust this number as needed
  end

  def text_uploads
    return nil unless current_user.allowed? 'pinboard.entity.edit'

    {
      purpose: :pinboard_commentable_text,
      size: 0..Rails.configuration.max_document_size,
    }
  end

  def attachment_upload
    FileUpload.new \
      purpose: :pinboard_commentable_attachment,
      size: 0..Rails.configuration.max_document_size,
      content_type: %w[
        application/pdf
        application/xml
        text/xml
        text/plain
        image/jpeg
        image/png
        image/gif
      ]
  end
end
