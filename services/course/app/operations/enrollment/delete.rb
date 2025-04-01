# frozen_string_literal: true

class Enrollment::Delete < ApplicationOperation
  attr_reader :enrollment

  def initialize(enrollment)
    super()
    @enrollment = enrollment
  end

  def call
    Enrollment.transaction do
      destroy_membership!
      enrollment.archive!
    end

    enrollment
  rescue ActiveRecord::RecordInvalid => e
    e.record
  rescue Restify::ResponseError
    enrollment.errors.add :base, 'error deleting membership'
    enrollment
  end

  private

  def account
    @account ||= Xikolo.api(:account).value!
  end

  def destroy_membership!
    return if enrollment.course.context_id.nil? # course not yet migrated

    user = enrollment.user_id
    group = enrollment.course.students_group_name
    account.rel(:memberships).delete({user:, group:}).value!
  end
end
