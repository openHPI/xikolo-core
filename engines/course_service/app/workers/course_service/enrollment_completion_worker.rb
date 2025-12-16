# frozen_string_literal: true

module CourseService
class EnrollmentCompletionWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(course_id, user_id = nil)
    course = Course.find(course_id)

    return unless course.records_released?

    enrollments = course.enrollments
    enrollments = enrollments.where(user_id:) if user_id
    enrollments = Enrollment.with_learning_evaluation(enrollments)

    enrollments.find_each do |completed_enrollment|
      Msgr.publish(EnrollmentDecorator.decorate(completed_enrollment).as_event,
        to: 'xikolo.course.enrollment.completed')
    end
  end
end
end
