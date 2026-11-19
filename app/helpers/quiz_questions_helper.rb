# frozen_string_literal: true

module QuizQuestionsHelper
  # Whether a learner has answered a question.
  #
  # For an in-progress quiz the current answers live in the autosave snapshot
  # (see `Xikolo::Submission::QuizSubmissionSnapshot#loaded_data`). For a
  # submitted quiz the answered answers live on the
  # `Xikolo::Submission::QuizSubmissionQuestion`. Questions without any answer
  # data are treated as unanswered.
  def question_answered?(question, snapshot: nil, submission_question: nil)
    if submission_question
      submission_question.quiz_submission_answers.present?
    elsif snapshot && (data = snapshot.loaded_data&.dig(question.id))
      case data
        when Array
          data.any?(&:present?)
        when Hash
          data.values.any?(&:present?)
        else
          data.present?
      end
    else
      false
    end
  end

  # Returns the result status of an auto-graded question: 'correct' when the
  # learner earned full points, 'incorrect' otherwise, and `nil` for questions
  # that are not auto-graded (essay) or when there is no submission question yet.
  def question_status(question, submission_question: nil)
    return nil unless submission_question
    return nil if question.is_a?(Xikolo::Quiz::EssayQuestion)

    max_points = question.points.to_f
    return nil if max_points.zero?

    submission_question.points.to_f >= max_points ? 'correct' : 'incorrect'
  end

  def question_type_options(quiz)
    options = [
      [t(:'quiz_questions.form.question_type.multiple_choice'), 'multiple_choice'],
      [t(:'quiz_questions.form.question_type.multiple_answer'), 'multiple_answer'],
    ]
    return options if quiz.question_pool

    options + [
      [t(:'quiz_questions.form.question_type.free_text'), 'free_text'],
      [t(:'quiz_questions.form.question_type.essay'), 'essay'],
    ]
  end

  # The maximum points a learner can earn in a single exam attempt. For
  # question-pool exams this is the total of the displayed question set
  # (10 questions per batch: 3 easy + 3 mid + 4 hard), not the whole pool.
  def displayed_max_points(quiz)
    return nil unless quiz.displayed_question_count.to_i.positive?

    batches = quiz.displayed_question_count.to_i / QuizService::Quiz::EXAM_QUESTIONS_PER_BATCH
    batches * QuizService::Quiz::EXAM_QUESTION_DIFFICULTIES
      .sum {|_difficulty, cfg| cfg[:points] * cfg[:count] }
  end
end
