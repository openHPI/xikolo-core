# frozen_string_literal: true

module QuizService
  class ReportQuizResultsJob < ApplicationJob
    queue_as :default

    def perform(submission_id)
      QuizSubmission.find(submission_id).report_result!
    end
  end
end
