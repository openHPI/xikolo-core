# frozen_string_literal: true

module CourseService
class Teacher < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :teachers

  validates :name, presence: true
  validate :description_not_empty
  after_commit :remove_replaced_picture

  after_commit :update_course_search_index, on: %i[update destroy]
  after_rollback :delete_already_uploaded_file

  scope :for_course, lambda {|course|
    from([
      Arel::Nodes::SqlLiteral.new('teachers'),
      Course.where(id: course).select('teacher_ids')
        .arel.as('teacher_ids'),
    ])
      .where(Arel.sql('teachers.id = ANY(teacher_ids.teacher_ids)'))
      .order(Arel.sql('array_position(teacher_ids.teacher_ids, teachers.id)'))
  }

  scope :filter_by_query, lambda {|query|
    sanitized_query = "%#{Teacher.sanitize_sql_like query}%"
    where('name ILIKE ?', sanitized_query)
  }

  def courses
    Course.where('? = ANY(teacher_ids)', id)
  end

  def picture_url
    Xikolo::S3.object(picture_uri).public_url if picture_uri?
  end

  def upload_via_id(upload_param)
    # Validate upload
    upload = Xikolo::S3::SingleFileUpload.new upload_param,
      purpose: 'course_teacher_picture'
    return if upload.empty?

    upload_object = upload.accepted_file!
    bucket = Xikolo::S3.bucket_for(:course)
    tid = UUID4(id).to_str(format: :base62)
    key = "teachers/#{tid}/#{upload_object.unique_sanitized_name}"
    object = bucket.object(key)

    # Save upload to xi-course bucket
    object.copy_from(
      upload_object,
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      content_type: upload_object.content_type,
      cache_control: 'public, max-age=7776000',
      content_disposition: 'inline'
    )
    @replaced_uri = picture_uri
    self.picture_uri = object.storage_uri
  rescue Aws::S3::Errors::ServiceError => e
    ::Sentry.capture_exception(e)
    errors.add :picture_upload_id, 'could not process file upload'
  rescue RuntimeError
    errors.add :picture_upload_id, 'invalid upload'
  end

  # TODO: As soon as backward compatibility is no longer needed,
  # TODO: this method can be rename to handle_picture or upload_picture
  def upload_via_uri(upload_param)
    # Check if picture shall be deleted (picture_uri == nil)
    if upload_param.nil?
      @replaced_uri = picture_uri
      remove_replaced_picture
      self.picture_uri = nil
      return
    end

    # Validate upload
    upload = Xikolo::S3::UploadByUri.new \
      uri: upload_param,
      purpose: 'course_teacher_picture'
    unless upload.valid?
      errors.add :picture_uri, 'Upload not valid - ' \
                               'either file upload was rejected or access to it is forbidden.'
      return
    end

    # Save upload to xi-course bucket
    tid = UUID4(id).to_str(format: :base62)
    result = upload.save \
      bucket: :course,
      key: "teachers/#{tid}/#{upload.upload.unique_sanitized_name}",
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_type: upload.content_type,
      content_disposition: 'inline'
    if result.is_a?(Symbol)
      errors.add :picture_uri, 'Could not save file - ' \
                               'access to destination is forbidden.'
      return
    end
    @replaced_uri = picture_uri
    self.picture_uri = result.storage_uri
  end

  private

  def remove_replaced_picture
    return unless @replaced_uri

    FileDeletionWorker.perform_in 1.hour, @replaced_uri
    @replaced_uri = nil
  end

  def delete_already_uploaded_file
    return unless @replaced_uri

    Xikolo::S3.object(picture_uri).delete
    @replaced_uri = nil
  end

  def description_not_empty
    invalid_description = description.nil? || !description.is_a?(Hash) ||
                          description.all? {|_key, value| value.blank? }
    errors.add(:description, :blank) if invalid_description
  end

  def update_course_search_index
    return unless saved_change_to_name?

    courses.pluck(:id).each {|course_id| UpdateCourseSearchIndexWorker.perform_async(course_id) }
  end
end
end
