# frozen_string_literal: true

module Items
  class QuizInfoPreview < ViewComponent::Preview
    def ready_question_pool
      render QuizInfo.new(quiz(status: status_for(complete_question_pool_criteria)))
    end

    def incomplete_question_pool
      render QuizInfo.new(quiz(status: status_for(incomplete_question_pool_criteria)))
    end

    def unsupported_question_type
      criteria = complete_question_pool_criteria
      criteria[-1] = criterion(:question_types_missing, fulfilled: false, count: 1)

      render QuizInfo.new(quiz(status: status_for(criteria)))
    end

    def standard_quiz
      render QuizInfo.new(quiz(question_pool: false))
    end

    private

    def quiz(question_pool: true, status: {})
      questions = complete_question_pool

      QuizService::Quiz.new(question_pool:).tap do |quiz|
        quiz.define_singleton_method(:question_pool_status) { status }
        quiz.define_singleton_method(:questions) { questions }
        quiz.define_singleton_method(:max_points) { 42 }
      end
    end

    def complete_question_pool_criteria
      [
        criterion(:questions_per_learner, count: 10),
        criterion(:pool_size, current_count: 30, required_count: 30),
        criterion(:difficulty, difficulty: 'easy', count: 23, required_count: 3),
        criterion(:difficulty, difficulty: 'mid', count: 3, required_count: 3),
        criterion(:difficulty, difficulty: 'hard', count: 4, required_count: 4),
        criterion(:question_types),
      ]
    end

    def incomplete_question_pool_criteria
      [
        criterion(:questions_per_learner, count: 10),
        criterion(:pool_size_missing, fulfilled: false, current_count: 0, required_count: 30, count: 30),
        criterion(:difficulty, fulfilled: false, difficulty: 'easy', count: 0, required_count: 3),
        criterion(:difficulty, fulfilled: false, difficulty: 'mid', count: 0, required_count: 3),
        criterion(:difficulty, fulfilled: false, difficulty: 'hard', count: 0, required_count: 4),
        criterion(:question_types),
      ]
    end

    def criterion(message, fulfilled: true, **options)
      {fulfilled:, message:, options:}
    end

    def status_for(criteria)
      QuizService::Quiz::QuestionPoolStatus.new(criteria[0], criteria[1], criteria[2...-1], criteria[-1])
    end

    def complete_question_pool
      [
        *Array.new(3) { Xikolo::Quiz::MultipleChoiceQuestion.new(points: 1) },
        *Array.new(3) { Xikolo::Quiz::MultipleChoiceQuestion.new(points: 2) },
        *Array.new(4) { Xikolo::Quiz::MultipleAnswerQuestion.new(points: 3) },
        *Array.new(20) { Xikolo::Quiz::MultipleChoiceQuestion.new(points: 1) },
      ]
    end
  end
end
