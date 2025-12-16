# frozen_string_literal: true

module CourseService
class Enrollment::Reactivate < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  def initialize(enrollment, submission_date)
    super()
    @enrollment = enrollment
    @submission_date = submission_date
  end

  def call
    ActiveRecord::Base.transaction do
      @enrollment.update! forced_submission_date: @submission_date

      FixedLearningEvaluation.where(user_id: @enrollment.user_id,
        course_id: @enrollment.course_id).delete_all

      create_feature_flipper!
      unlock_graded_assignments!
    end

    @enrollment
  rescue Restify::ResponseError => e
    @enrollment.errors.add :remote_error, e
    @enrollment
  end

  private

  def create_feature_flipper!
    Xikolo.api(:account).value!
      .rel(:user)
      .get({id: @enrollment.user_id})
      .value!
      .rel(:features)
      .patch(
        {'course.reactivated' => true},
        params: {context: @enrollment.course.context_id}
      ).value!
  end

  def unlock_graded_assignments!
    # TODO: think about refactoring to async as soon as there will be more
    # actions to be triggered on reactivation
    Xikolo.api(:quiz).value!
      .rel(:user_quiz_attempts)
      .post({user_id: @enrollment.user_id, course_id: @enrollment.course_id})
      .value!
  end
end
end
