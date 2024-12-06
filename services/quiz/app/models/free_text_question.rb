# frozen_string_literal: true

class FreeTextQuestion < Question
  def shuffle_answers=(_shuffle)
    super(false)
  end

  def update_points_from_submission(submission_question, answer_param)
    raise ArgumentError unless answer_param.is_a? Hash

    update_points(submission_question, answer_param.first[1].strip)
  end

  def update_points_from_answer_object(submission_question, user_answers)
    update_points(submission_question, user_answers.first.user_answer_text)
  end

  def create_answer!(submission_question, answer_param)
    raise ArgumentError unless answer_param.is_a? Hash

    answer = QuizSubmissionFreeTextAnswer.new(
      quiz_answer_id: answer_param.first[0],
      user_answer_text: answer_param.first[1].strip
    )

    # Ensure answers are not too long
    ActiveModel::Validations::LengthValidator.new(
      maximum: 255,
      attributes: [:user_answer_text]
    ).validate(answer)

    raise ActiveRecord::RecordInvalid.new(answer) unless answer.errors.empty?

    submission_question.quiz_submission_answers << answer
  end

  def stats
    @stats ||= FreeTextQuestionStats.new(question_id: id)
  end

  private

  def update_points(submission_question, user_answer_text)
    points = 0
    answers.where(correct: true).find_each do |possible_answer|
      points = self.points if evaluate_answer(possible_answer.text, user_answer_text)
    end
    submission_question.update points:
  end

  def evaluate_answer(possible_answer, user_answer)
    if case_sensitive
      user_answer.include? possible_answer
    else
      user_answer.downcase.include? possible_answer.downcase
    end
  end
end
