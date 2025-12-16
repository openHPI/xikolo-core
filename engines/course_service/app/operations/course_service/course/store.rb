# frozen_string_literal: true

module CourseService
class Course::Store < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  class OperationError < StandardError; end

  attr_reader :course

  def initialize(course, params)
    super()
    @course = course
    @params = params
    @replaced_uris = []
    @new_uris = []
    @upload_errors = {}
  end

  protected

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :course,
      purpose: 'course_course_description',
      current: course.description,
      text: input,
      valid_refs: Xikolo::S3.extract_file_refs(course.description)
    processor.on_new do |upload|
      cid = UUID4(course.id).to_str(format: :base62)
      id = UUID4.new.to_str(format: :base62)
      {
        key: "courses/#{cid}/rtfiles/#{id}/#{upload.sanitized_name}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: 'inline',
        content_type: upload.content_type,
      }
    end
  end

  def update
    # Upload course stage visual
    if @params.key?(:stage_visual_uri)
      upload_via_uri('stage_visual', @params[:stage_visual_uri],
        'course_course_stage_visual')
    elsif @params.key?(:stage_visual_upload_id)
      upload_via_id('stage_visual', @params[:stage_visual_upload_id],
        'course_course_stage_visual')
    end

    if @upload_errors.blank?
      remove_replaced_visuals!

      if !@params.key? :description
        course.update @params.except(*file_upload_params)
      elsif (description = @params.delete(:description))
        course.assign_attributes @params.except(*file_upload_params)
        configure_processor! description
        process_description_and_save
      else
        course.assign_attributes @params.except(*file_upload_params)
        course.description = nil
        course.save
      end
    else
      process_errors!
    end
  end

  def process_description_and_save
    processor.parse!
    course.description = processor.result
    if processor.valid? && course.save
      commit!
    else
      rollback!
    end
  end

  def commit!
    processor.commit!
    processor.obsolete_uris.each do |uri|
      RichtextFileDeletionWorker.perform_in 1.hour, uri
    end
    true
  end

  def rollback!
    processor.rollback!
    processor.errors.each do |_url, code, _message|
      course.errors.add :description, code.to_s
    end
    delete_already_uploaded_files!

    false
  end

  private

  def account
    @account ||= Xikolo.api(:account).value!
  end

  def grant_visitor!
    # no need to grant course.visitor if course is in preparation
    return if @course.status == 'preparation'

    # grant course.visitor to all users if no group restrictions
    if @course.groups.empty?
      grant! role: 'course.visitor', group: 'all'
      return
    end

    @course.groups.each do |group|
      grant! role: 'course.visitor', group:
    end
  end

  def grant!(role:, group:, context: 'course')
    grant_data = {
      group:,
      context: evaluate_context(context),
      role:,
    }

    account.rel(:grants).post(grant_data).value!
  rescue Restify::ResponseError => e
    raise_operation_error e, 'error granting role'
  end

  def evaluate_context(context)
    if context == 'course'
      @course.context_id
    else
      context
    end
  end

  def raise_operation_error(error, message)
    ::Sentry.capture_exception(error)
    raise OperationError.new message
  end

  def file_upload_params
    %i[stage_visual_upload_id stage_visual_uri visual_uri]
  end

  def upload_via_id(upload_name, upload_value, purpose)
    # Validate upload
    upload = Xikolo::S3::SingleFileUpload.new(upload_value,
      purpose:)
    return if upload.empty?

    upload_object = upload.accepted_file!
    bucket = Xikolo::S3.bucket_for(:course)
    uid = UUID4(@course.id).to_str(format: :base62)
    key = "courses/#{uid}/#{upload_object.unique_sanitized_name}"
    object = bucket.object(key)

    # Save upload to xi-course's bucket (xikolo-public)
    object.copy_from(
      upload_object,
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_type: upload_object.content_type,
      content_disposition: 'inline'
    )
    @replaced_uris << @course["#{upload_name}_uri"]
    @course["#{upload_name}_uri"] = object.storage_uri
    @new_uris << object.storage_uri
  rescue Aws::S3::Errors::ServiceError => e
    Sentry.capture_exception(e)
    @upload_errors[:"#{upload_name}_upload_id"] =
      'could not process file upload'
  rescue RuntimeError
    @upload_errors[:"#{upload_name}_upload_id"] = 'invalid upload'
  end

  def upload_via_uri(upload_name, upload_value, purpose)
    # Check if the upload object shall be deleted (uri == nil)
    if upload_value.nil?
      @replaced_uris << @course["#{upload_name}_uri"]
      remove_replaced_visuals!
      @course["#{upload_name}_uri"] = nil
      return
    end

    # Validate upload
    upload = Xikolo::S3::UploadByUri.new(uri: upload_value,
      purpose:)
    unless upload.valid?
      @upload_errors[:"#{upload_name}_uri"] = 'Upload not valid - ' \
                                              'either file upload was rejected or access to it is forbidden.'
      return
    end

    # Save upload to xi-course's bucket (xikolo-public)
    uid = UUID4(@course.id).to_str(format: :base62)
    result = upload.save \
      bucket: :course,
      key: "courses/#{uid}/#{upload.upload.unique_sanitized_name}",
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_type: upload.content_type,
      content_disposition: 'inline'
    if result.is_a?(Symbol)
      @upload_errors[:"#{upload_name}_uri"] = 'Could not save file - ' \
                                              'access to destination is forbidden.'
      return
    end
    @replaced_uris << @course["#{upload_name}_uri"]
    @course["#{upload_name}_uri"] = result.storage_uri
    @new_uris << result.storage_uri
  end

  def process_errors!
    delete_already_uploaded_files!
    @upload_errors.each {|key, error| @course.errors.add key, error }
  end

  def remove_replaced_visuals!
    return if @replaced_uris.empty?

    @replaced_uris.each {|uri| FileDeletionWorker.perform_in 1.hour, uri }
    @replaced_uris = []
  end

  def delete_already_uploaded_files!
    # To ensure atomicity (in case of a failing update action)
    @new_uris.each {|uri| Xikolo::S3.object(uri).delete }
  end
end
end
