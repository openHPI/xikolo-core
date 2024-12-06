# frozen_string_literal: true

class MultipleAnswerQuestion < Question
  def update_points_from_answer_object(submission_question, user_answers)
    update_points submission_question, user_answers.map(&:quiz_answer_id)
  end

  def update_points_from_submission(submission_question, answer_param)
    update_points submission_question, Array.wrap(answer_param)
  end

  def create_answer!(submission_question, answer_param)
    Array.wrap(answer_param).each do |answer_id|
      QuizSubmissionSelectableAnswer.create! quiz_submission_question_id: submission_question.id,
        quiz_answer_id: answer_id
    end
  end

  def stats
    # This is on purpose, the MultipleAnswerQuestion provides the same stats
    # as the MultipleChoiceQuestion (until someone wishes to add something).
    @stats ||= MultipleChoiceQuestionStats.new(question_id: id)
  end

  private

  # From the openHPI Certificate Guidelines:
  # "With multiple-answer tasks the number of points achieved for a partially correct solution is calculated
  # in the following way. The maximum number of points is divided by the number of correct alternatives
  # and this value is used as the base. For every right alternative that has been correctly selected,
  # the base value will be given. For every false alternative, the base value will be subtracted.
  # If the total result is negative, then 0 points are given.
  # For example, a maximum of 3 points are possible for one task. Three out of five answers are correct.
  # The student has marked two correct and one false. For both of the correct answers
  # he receives one point each (3 divided by 3), for the false answer one point is subtracted.
  # He therefore receives one point for the task."
  def update_points(submission_question, user_answer_ids)
    correct_answers = answers.where(correct: true)
    return submission_question.update points: 0 if correct_answers.empty?

    points = 0
    points_per_answer = self.points / correct_answers.length.to_f
    user_answer_ids.each do |user_answer_id|
      if correct_answers.ids.include? user_answer_id
        points += points_per_answer
      else
        points -= points_per_answer
      end
    end
    points = [0, points.to_f].max # if points are < 0, give 0 points for this question
    submission_question.update points:
  end
end
