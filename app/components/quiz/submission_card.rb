# frozen_string_literal: true

module Quiz
  class SubmissionCard < ApplicationComponent
    def initialize(quiz, item_presenter:, submission: nil, my_result: nil, counter_end_timediff: nil)
      @quiz = quiz
      @item_presenter = item_presenter
      @submission = submission
      @my_result = my_result
      @counter_end_timediff = counter_end_timediff
    end

    private

    def show_results
      !@item_presenter.survey? && @item_presenter.show_quiz_results? && @submission.present? && @submission.submitted
    end

    def show_points
      @item_presenter.graded?
    end

    def show_attempts
      !@item_presenter.survey?
    end

    def show_time
      !show_results
    end

    def divider
      'border-l border-base-content/10'
    end

    def question_statuses
      @question_statuses ||= begin
        statuses = {}
        if show_results
          @quiz.questions.each do |q|
            submission_question = @submission.get_user_submission_question_for(q.id)
            statuses[q.id] = helpers.question_status(q, submission_question:) if submission_question
          end
        end
        statuses
      end
    end
  end
end
