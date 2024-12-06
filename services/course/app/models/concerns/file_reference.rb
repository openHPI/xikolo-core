# frozen_string_literal: true

module FileReference
  extend ActiveSupport::Concern

  included do
    validate :validate_s3_reference_or_upload
    after_commit :delete_old_s3_references
    after_rollback :delete_wrongly_uploaded_files
  end

  module ClassMethods
    @default_file_params = {}
    def file_reference(name, params_labmda, params = {})
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{name}_url                                               # def filename_url
          Xikolo::S3.object(#{name}_uri).public_url if #{name}_uri?   #   Xikolo::S3.object(filename_uri).public_url if filename_uri?
        end                                                           # end
      RUBY_EVAL

      purpose = params[:purpose] || "course_#{self.name.to_s.downcase}_#{name}"

      # rubocop:disable Style/DocumentDynamicEvalDefinition
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{name}_upload_id=(upload_id)
          @upload_error ||= {}
          @new_objects ||= []
          @replaced_objects ||= []
          upload = Xikolo::S3::SingleFileUpload.new upload_id,
            purpose: :"#{purpose}"
          return if upload.empty?

          upload_object = upload.accepted_file!
          bucket = Xikolo::S3.bucket_for(:course)

          /.*_[rv](?<revision>[0-9]+)(.[a-z]{2,4})?/ =~ #{name}_uri
          revision ||= 0

          params_lambda = self.class.file_reference_params(:#{name})
          params = params_lambda.call(self, revision.to_i + 1, upload_object)
          object = bucket.object(params.delete(:key))
          object.copy_from(
            upload_object,
            params.merge(metadata_directive: 'REPLACE'),
          )
          @new_objects << object.storage_uri
          @replaced_objects << #{name}_uri if #{name}_uri?
          self.#{name}_uri = object.storage_uri
        rescue Aws::S3::Errors::ServiceError => err
          Mnemosyne.attach_error err
          @upload_error[:#{name}] = 'could not process file upload'
        rescue RuntimeError
          @upload_error[:#{name}] = 'invalid upload'
        end
      RUBY_EVAL
      # rubocop:enable all

      @file_reference_params ||= {}
      @file_reference_params[name] = params_labmda
    end

    def file_reference_params(name)
      @file_reference_params.fetch(name)
    end
  end

  private

  def validate_s3_reference_or_upload
    return if @upload_error.nil?

    @upload_error.each do |key, error|
      errors.add :"#{key}_upload_id", error
    end
  end

  def delete_old_s3_references
    # schedule deletion of all replaced S3 objects:
    @replaced_objects&.each do |uri|
      FileDeletionWorker.perform_in 1.hour, uri
    end
    @replaced_objects = nil
  end

  def delete_wrongly_uploaded_files
    # we remove all new_objects:
    @new_objects&.each do |uri|
      Xikolo::S3.object(uri).delete
    end
    @new_objects = nil
  end
end
