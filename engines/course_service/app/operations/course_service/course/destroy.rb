# frozen_string_literal: true

module CourseService
class Course::Destroy < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  attr_reader :course, :code

  def initialize(course)
    super()
    @course = course
    @code = course.course_code
  end

  def call
    # We change the course code of the deleted course, to "free" the name again
    # for use in a new course. (Maybe the deleted course was a failed
    # experiment, and it was decided to throw it away and start over.)
    deleted_code = "#{course.course_code}-deleted-" \
      + Digest::MD5.hexdigest(Time.now.utc.to_s)
    course.update! deleted: true, course_code: deleted_code

    destroy_special_groups!
    destroy_context!
    destroy_referenced_files!
    course
  end

  private

  def destroy_special_groups!
    Xikolo.config.course_groups.each_key.map do |name|
      account_api.rel(:group).delete({id: "course.#{code}.#{name}"})
    end.each(&:value!)
  rescue Restify::ServerError, Restify::ClientError => e
    Sentry.capture_exception(e)
  end

  def destroy_context!
    account_api.rel(:context).delete({id: course.context_id}).value!
  rescue Restify::ServerError, Restify::ClientError => e
    Sentry.capture_exception(e)
  end

  def destroy_referenced_files!
    Xikolo::S3.object(course.stage_visual_uri).delete if course.stage_visual_uri?
  rescue Aws::S3::Errors::ServiceError => e
    Sentry.capture_exception(e)
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
end
