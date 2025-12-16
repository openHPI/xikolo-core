# frozen_string_literal: true

module CourseService
class EnrollmentGroupWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(course_id, user_id)
    Enrollment
      .find_by!(course_id:, user_id:, deleted: false)
      .create_membership!
  rescue ActiveRecord::RecordNotFound
    # This should never be called without an enrollment.
  end
end
end
