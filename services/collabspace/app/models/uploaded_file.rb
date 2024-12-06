# frozen_string_literal: true

class UploadedFile < ApplicationRecord
  require 'errors'

  self.table_name = 'files'

  ##
  # We cannot name this model "File", as that would clash with Ruby's very own
  # +File+ class. Therefore, this method tells Rails to treat this model as
  # "File" where possible, e.g. when inferring decorator names.
  #
  def self.model_name
    ActiveModel::Name.new self, nil, 'File'
  end

  belongs_to :collab_space
  has_many :versions,
    class_name: 'FileVersion',
    foreign_key: 'file_id',
    dependent: :destroy,
    inverse_of: :file
  validates :title, presence: true

  def file_data
    @file_data ||= versions.first
  end

  def process_upload!(upload_uri)
    # Validate upload
    upload = Xikolo::S3::UploadByUri.new \
      uri: upload_uri,
      purpose: 'collabspace_file'
    raise Errors::InvalidUpload unless upload.valid?

    cid = UUID4(collab_space_id).to_s(format: :base62)
    fid = UUID4(id).to_s(format: :base62)
    file_name = upload.sanitized_name

    # Create corresponding file version
    version = versions.build \
      id: UUID4.new.to_str,
      original_filename: file_name,
      size: upload.upload.size
    vid = UUID4(version.id).to_str(format: :base62)

    # Save upload to xi-collabspace bucket
    result = upload.save \
      bucket: :collabspace,
      key: "collabspaces/#{cid}/files/#{fid}/#{vid}/#{file_name}",
      content_disposition: "attachment; filename=\"#{file_name}\"",
      content_type: upload.content_type,
      acl: 'private'
    raise Errors::InvalidUpload if result.is_a?(Symbol)

    version.blob_uri = result.storage_uri
    version.save!
  end
end
