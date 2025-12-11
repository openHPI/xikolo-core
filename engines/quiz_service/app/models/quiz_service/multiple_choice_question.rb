# frozen_string_literal: true

module QuizService
class MultipleChoiceQuestion < Question # rubocop:disable Layout/IndentationWidth
  def update_points_from_answer_object(submission_question, user_answers)
    update_points submission_question, user_answers.first.quiz_answer_id
  end

  def update_points_from_submission(submission_question, answer_param)
    raise ArgumentError unless answer_param.is_a? String

    update_points submission_question, answer_param
  end

  def create_answer!(submission_question, answer_param)
    raise ArgumentError unless answer_param.is_a? String

    QuizSubmissionSelectableAnswer.create! quiz_submission_question_id: submission_question.id,
      quiz_answer_id: answer_param
  end

  def stats
    @stats ||= MultipleChoiceQuestionStats.new(question_id: id)
  end

  private

  def update_points(submission_question, user_answer_id)
    user_answer = Answer.find user_answer_id
    submission_question.update(
      points: user_answer.correct ? points : 0
    )
  end
end
end
