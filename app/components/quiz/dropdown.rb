# frozen_string_literal: true

module Quiz
  class Dropdown < ApplicationComponent
    def initialize(question, submission: nil, snapshot: nil)
      @question = question
      @submission = submission
      @snapshot = snapshot
    end

    private

    def answer_options
      [default_answer] + question_answers
    end

    def default_answer
      [t(:'quiz_submission.please_select'), '']
    end

    def question_answers
      @question.answers.map do |a|
        [a.text, a.id]
      end
    end

    def selected_answers
      if @submission
        @submission.quiz_submission_answers.map(&:quiz_answer_id)
      elsif !@snapshot.nil? && !@snapshot.loaded_data.nil? && !@snapshot.loaded_data[@question.id].nil?
        @snapshot.loaded_data[@question.id]
      else
        [default_answer[1]]
      end
    end

    def disabled_answers
      [default_answer[1]]
    end
  end
end
