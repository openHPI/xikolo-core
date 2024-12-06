# frozen_string_literal: true

##
# A class representing an upload ticket to our S3 object storage.
#
# Based on the provided metadata / options, this will generate a presigned URL
# that can be used by the frontend (i.e. JavaScript code) as a destination for
# direct uploads.
#
# Available options:
# - purpose: A category, to be stored with the upload - backends will only
#     accept uploads with expected purposes (and move them to their bucket).
# - content_type: One or multiple allowed content types. Possible values:
#     * a string (used in upload dialogs, and enforced by S3 when uploading)
#     * an array of content types (will be whitelisted in upload dialogs)
#     * a prefix (e.g. "image/*" for matching multiple types, also enforced)
# - size: The maximum allowed file size in bytes
# - image_width: For images, the maximum allowed width in pixels
# - image_height: For images, the maximum allowed height in pixels
#
class FileUpload
  attr_reader :id, :content_type, :size

  def initialize(purpose:,
                 content_type: nil,
                 size: nil,
                 image_width: nil,
                 image_height: nil)
    @purpose = purpose
    @size = size
    @content_type = content_type
    @image_height = image_height
    @image_width = image_width
    @id = UUID4.new
  end

  def url
    compute!
    @upload.url
  end

  def fields
    compute!
    @upload.fields
  end

  def prefix
    "uploads/#{id}/"
  end

  def extension_filter
    return @filter if defined? @filter
    return @filter = [] unless @content_type

    compute!
    @filter = []
    content_type.split(',').each do |filter|
      if filter.ends_with?('*')
        prefix = filter[0..-2]
        self.class.mime_type_mapping.each_pair do |mime, ext|
          next unless mime.starts_with? prefix

          @filter.push ext unless @filter.include? ext
        end
        next
      elsif self.class.mime_type_mapping.include? filter
        ext = self.class.mime_type_mapping[filter]
      elsif filter[0] == '.'
        ext = filter[1..]
      end
      @filter.push ext unless @filter.include? ext
    end
    @filter
  end
  # rubocop:enable all

  def self.mime_type_mapping
    @mime_type_mapping ||= {
      'application/pdf' => 'pdf',
      'application/vnd.ms-powerpoint' => 'ppt',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'pptx',
      'application/vnd.oasis.opendocument.presentation' => 'odp',
      'application/msword' => 'doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx',
      'application/vnd.oasis.opendocument.text' => 'odt',
      'application/vnd.ms-excel' => 'xls',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'xlsx',
      'application/vnd.oasis.opendocument.spreadsheet' => 'ods',
      'application/xml' => 'xml',
      'application/zip' => 'zip',
      'text/xml' => 'xml',
      'text/plain' => 'txt',
      'text/vtt' => 'vtt',
      'text/comma-separated-values' => 'csv',
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/gif' => 'gif',
    }.freeze
  end

  private

  def compute!
    return if @upload

    bucket = Xikolo::S3.bucket_for(:uploads)
    metadata = {
      'xikolo-purpose' => @purpose.to_s,
      'xikolo-state' => 'accepted',
    }
    metadata['image-target-height'] = @image_height.to_s if @image_height
    metadata['image-target-width'] = @image_width.to_s if @image_width
    params = {
      key_starts_with: prefix,
      acl: 'private',
      signature_expiration: 3.hours.from_now,
      metadata:,
    }
    if @content_type.nil?
      params[:allow_any] = %w[Content-Type]
    elsif @content_type.is_a?(Array)
      params[:allow_any] = %w[Content-Type]
      @content_type = @content_type.join(',')
    elsif @content_type.ends_with?('*')
      params[:content_type_starts_with] = @content_type[0..-2]
    else
      params[:content_type] = @content_type
    end
    params[:content_length_range] = @size if @size
    @upload = bucket.presigned_post(params)
  end
end
