# frozen_string_literal: true

class FileVersion < ApplicationRecord
  belongs_to :file, class_name: 'UploadedFile'
  after_destroy_commit :delete_s3_object

  private

  def delete_s3_object
    Xikolo::S3.object(blob_uri).delete
  end
end
