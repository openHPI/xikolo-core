# frozen_string_literal: true

class AttemptsHandler
  include UserQuizAttemptsHelper

  attr_reader :course_id, :user_id

  def initialize(course_id, user_id)
    @course_id = course_id
    @user_id = user_id
  end

  def unlock_assignments
    # TODO: throw rollback event if error occurs
    course_service = Xikolo.api(:course).value!
    sections = course_service.rel(:sections).get({course_id:}).value!
    quiz_items = sections.map do |section|
      course_service
        .rel(:items)
        .get({section_id: section['id'], content_type: 'quiz', exercise_type: 'main'})
    end.flat_map(&:value!)

    quiz_items.each do |quiz_item|
      quiz = Quiz.find quiz_item['content_id']
      attempts = UserQuizAttempts.new user_id:, quiz_id: quiz_item['content_id']

      unless attempts_for_quiz_remaining?(attempts, quiz)
        grant_additional_attempt(user_id, quiz_item['content_id'])
      end
    end
  end

  private

  def attempts_for_quiz_remaining?(user_attempts, quiz)
    user_attempts.attempts < quiz.current_allowed_attempts + user_attempts.additional_attempts
  end
end
