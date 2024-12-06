# frozen_string_literal: true

class ReportQuizResultsWorker
  include Sidekiq::Job

  def perform(submission_id)
    QuizSubmission.find(submission_id).report_result!
  end
end
