# frozen_string_literal: true

module UserTestsHelper
  def active_user_tests
    %w[
      mobile.content_notification_and_downloads
      mobile.native_quiz_recap_with_notifications
    ]
  end

  def experiment(identifier)
    Experiment.new(identifier, course_id:)
  end

  private

  def course_id
    the_course.id
  rescue
    nil
  end
end
