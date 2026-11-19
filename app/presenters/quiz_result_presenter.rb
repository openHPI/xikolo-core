# frozen_string_literal: true

class QuizResultPresenter
  include ProgressHelper

  def initialize(quiz, submission, all_submissions)
    @quiz = quiz
    @submission = submission
    @all_submissions = all_submissions
  end

  ##
  # Determine the achieved percentage in the current submission
  #
  def percentage
    calc_progress(@submission['points'], max_points)
  end

  def max_points
    @submission['max_points'] || @quiz['max_points']
  end

  ##
  # Did the learner pass the exam with this submission? Only meaningful for
  # exams (question-pool quizzes); returns `false` for all other quiz types.
  #
  def exam?
    @quiz['question_pool'] == true
  end

  def passed?
    return false unless exam?

    max = max_points.to_f
    return false if max.zero?

    @submission['points'].to_f * 100 / max >= (@quiz['pass_percentage'] || 70)
  end
end
