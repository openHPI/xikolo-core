# frozen_string_literal: true

class CourseProgress::Calculate < ApplicationOperation
  def initialize(course_id, user_id)
    super()

    @course_id = course_id
    @user_id = user_id
  end

  def call
    course_progress.calculate!

    course_progress
  end

  private

  def course_progress
    @course_progress ||= CourseProgress.find_or_create_by!(
      user_id: @user_id,
      course_id: @course_id
    )
  rescue ActiveRecord::RecordNotUnique
    # Retry on race condition in between find and create.
    retry
  end
end
