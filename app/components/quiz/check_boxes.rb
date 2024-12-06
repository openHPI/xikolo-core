# frozen_string_literal: true

module Quiz
  class CheckBoxes < ApplicationComponent
    def initialize(question, lang:, submission: nil, snapshot: nil, show_solution: false)
      @question = question
      @lang = lang
      @submission = submission
      @snapshot = snapshot
      @show_solution = show_solution
    end

    private

    def answers
      user_answers = if @show_solution && @submission
                       @submission.quiz_submission_answers.map(&:quiz_answer_id)
                     elsif !@snapshot.nil? && !@snapshot.loaded_data.nil? && !@snapshot.loaded_data[@question.id].nil?
                       @snapshot.loaded_data[@question.id]
                     else
                       []
                     end

      @question.answers.map do |a|
        AnswerWrapper.new a, show_solution: @show_solution, selected: user_answers.include?(a.id)
      end
    end

    class AnswerWrapper
      def initialize(answer, show_solution:, selected:)
        @answer = answer
        @show_solution = show_solution
        @selected = selected
      end

      def id
        @answer.id
      end

      def text
        @answer.text
      end

      def comment
        @answer.comment
      end

      def correct?
        @answer.correct
      end

      def css_classes
        @show_solution ? 'show-solution' : ''
      end

      def disabled?
        @show_solution
      end

      def edited?
        !@show_solution && @selected
      end

      def selected?
        @selected
      end
    end
  end
end
