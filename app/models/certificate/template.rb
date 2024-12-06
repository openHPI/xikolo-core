# frozen_string_literal: true

module Certificate
  class Template < ::ApplicationRecord
    CERTIFICATE_TYPES = ::Certificate::Record::TYPES.map(&:to_sym).freeze
    SVG_XSD = Rails.root.join('vendor', 'assets', 'schemas', 'svg', 'svg.xsd').freeze

    validates :certificate_type, uniqueness: {scope: :course_id}
    validate :allowed_certificate_type
    validate :valid_s3_reference_or_upload
    validate :valid_xml

    belongs_to :course, class_name: 'Course::Course'
    has_many :records,
      class_name: '::Certificate::Record',
      dependent: :destroy

    default_scope { order('updated_at DESC') }

    after_commit :delete_s3_object!, on: :destroy

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with OpenBadgeTemplate instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'CertificateTemplate')
    end

    def to_param
      id
    end

    # If there is already a Transcript of Records template, there can't be any other
    # certificate for that course and vice versa.
    def allowed_types
      return CERTIFICATE_TYPES.excluding(:TranscriptOfRecords) unless Xikolo.config.certificate['transcript_of_records']

      existing_template_types = course.certificate_templates.pluck(:certificate_type)

      return CERTIFICATE_TYPES if existing_template_types.blank?
      return %i[TranscriptOfRecords] if existing_template_types.include?('TranscriptOfRecords')

      CERTIFICATE_TYPES.excluding(:TranscriptOfRecords)
    end

    def preview_for(user_id)
      PreviewRecord.new(self, Account::User.find(user_id))
    end

    def record_for!(user_id)
      records.find_or_create_by!(
        course:,
        user_id:,
        type: certificate_type
      )
    rescue ActiveRecord::RecordNotUnique
      # Handle possible race condition in find_or_create_by!
      retry
    end

    def file_url
      # Return a presigned download URL.
      Xikolo::S3.object(file_uri).presigned_url(:get, expires_in: 300) if file_uri?
    end

    def process_upload!(upload_id)
      @upload_error = false
      return unless valid?

      upload = Xikolo::S3::SingleFileUpload.new upload_id,
        purpose: 'certificate_template'
      @upload_error = nil
      return if upload.empty?

      upload_object = upload.accepted_file!
      original_filename = File.basename upload_object.key
      extname = File.extname original_filename
      bucket = Xikolo::S3.bucket_for(:certificate)
      tid = UUID4(id).to_s(format: :base62)
      object = bucket.object("templates/#{tid}#{extname}")
      object.copy_from(
        upload_object,
        metadata_directive: 'REPLACE',
        acl: 'private',
        content_type: upload_object.content_type,
        content_disposition: "attachment; filename=\"#{original_filename}\""
      )
      self.file_uri = object.storage_uri
    rescue Aws::S3::Errors::ServiceError => e
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)
      @upload_error = 'could not process file upload'
    rescue RuntimeError
      @upload_error = 'invalid upload'
    end

    private

    def allowed_certificate_type
      return true if allowed_types.include?(certificate_type.to_sym)

      errors.add :certificate_type, :not_allowed
    end

    def valid_s3_reference_or_upload
      if @upload_error
        errors.add :file_upload_id, @upload_error
      elsif @upload_error == false
        # We are in process_upload!, ignore for now.
      elsif !file_uri?
        errors.add :file_upload_id, 'upload missing'
      end
    end

    def delete_s3_object!
      S3FileDeletionJob.perform_now(file_uri)
    end

    def valid_xml
      REXML::Document.new dynamic_content
    rescue REXML::ParseException
      errors.add(:dynamic_content, :invalid_xml)
    else
      # Since ReXML does not support XML Schema validation, we use a different library (Nokogiri).
      validate_schema(dynamic_content)
    end

    def validate_schema(dynamic_content)
      schema = Nokogiri::XML::Schema(File.open(SVG_XSD))
      xml = Nokogiri::XML(dynamic_content)

      if (validation_errors = schema.validate(xml)).present?
        errors.add(:dynamic_content, :invalid_xml, message: validation_errors.map(&:message).join("\n"))
      end

      # The font check only works as expected on a semantically valid document
      if errors.empty?
        # Extract all font-family attribute values
        font_families = xml.xpath('//@font-family').map(&:value).uniq
        # Check if all font families are defined in the configuration
        if (missing_fonts = font_families - configured_fonts).any?
          errors.add(:dynamic_content, :invalid_font,
            message: I18n.t('errors.messages.certificate_templates.missing_fonts',
              missing_fonts: missing_fonts.join(', '), configured_fonts: configured_fonts.join(', ')))
        end
      end
    end

    def configured_fonts
      Xikolo.config.certificate&.dig('fonts')&.keys.presence ||
        %w[OpenSansRegular OpenSansSemibold]
    end
  end
end
