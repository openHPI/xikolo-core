# frozen_string_literal: true

module Collabspace
  class FileForm < XUI::Form
    self.form_name = 'collabspace_file'

    attribute :file_upload_id, :upload,
      purpose: :collabspace_file,
      size: 0..Rails.configuration.max_document_size,
      content_type: %w[
        application/pdf
        application/xml
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
        application/vnd.openxmlformats-officedocument.presentationml.presentation
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
        application/vnd.oasis.opendocument.text
        application/vnd.oasis.opendocument.presentation
        application/vnd.oasis.opendocument.spreadsheet
        text/plain
        text/xml
        text/comma-separated-values
        image/jpeg
        image/png
        image/gif
      ]

    validates :file_upload_id, presence: true
  end
end
