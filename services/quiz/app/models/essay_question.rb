# frozen_string_literal: true

class EssayQuestion < Question
  def update_points_from_submission(submission_question, answer_param)
    raise ArgumentError unless answer_param.is_a? String

    submission_question.update points:
  end

  def update_points_from_answer_object(submission_question, _user_answers)
    submission_question.update points:
  end

  def create_answer!(submission_question, answer_param)
    raise ArgumentError unless answer_param.is_a? String

    submission_question.quiz_submission_answers << QuizSubmissionFreeTextAnswer.new(
      user_answer_text: answer_param
    )
  end

  def stats
    @stats ||= EssayQuestionStats.new(question_id: id)
  end
end
