# frozen_string_literal: true

module Items
  class QuizInfo < ApplicationComponent
    def initialize(quiz)
      @quiz = quiz
    end

    def question_pool?
      @quiz.question_pool
    end

    def valid?
      question_pool? && question_pool_status.valid?
    end

    def criteria
      question_pool_status.criteria
    end

    private

    def question_pool_status
      @quiz.question_pool_status
    end

    def criterion_text(criterion)
      options = criterion.fetch(:options)
      options[:difficulty] = helpers.t("items.quiz_info.difficulties.#{options[:difficulty]}") if options[:difficulty]
      helpers.t("items.quiz_info.#{criterion.fetch(:message)}", **options)
    end

    def questions
      @quiz.questions || []
    end
  end
end
