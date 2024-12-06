# frozen_string_literal: true

class Enrollment::Create < ApplicationOperation
  class OperationError < StandardError; end

  attr_reader :user_id, :params, :enrollment

  def initialize(user_id, course, params = {})
    super()
    @user_id = user_id
    @course = course
    @params = params
  end

  def course_id
    @course.id
  end

  def call
    begin
      Enrollment.transaction do
        @enrollment = Enrollment.where(
          user_id:,
          course_id: @course.id
        ).first_or_initialize

        validate_course_group_restrictions!

        update_fields!
        create_membership!
      end
    rescue OperationError => e
      enrollment.errors.add :base, e.message
      return enrollment
    rescue ActiveRecord::RecordInvalid => e
      return e.record
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    announce_creation!

    enrollment
  end

  private
  def validate_course_group_restrictions!
    return if @course.groups.empty?

    if Course.where(id: @course.id).for_groups(user: enrollment.user_id).empty?
      raise OperationError.new 'access_restricted'
    end
  end

  def update_fields!
    enrollment.role = 'student'
    enrollment.proctored = params[:proctored] unless params[:proctored].nil?
    enrollment.deleted = false
    enrollment.save!
  end

  def create_membership!
    return if @course.context_id.nil? # course not yet migrated
    unless prerequisites.status_for(enrollment.user_id).fulfilled?
      raise OperationError.new 'prerequisites_unfulfilled'
    end

    enrollment.create_membership!
  rescue Restify::ResponseError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
    raise OperationError.new 'membership_creation_failed'
  end

  def announce_creation!
    Msgr.publish(enrollment.decorate.as_event, to: 'xikolo.course.enrollment.create')
  end

  def prerequisites
    @course.prerequisites
  end
end
