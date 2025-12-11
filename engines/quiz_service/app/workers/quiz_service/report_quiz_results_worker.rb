# frozen_string_literal: true

module QuizService
class ReportQuizResultsWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(submission_id)
    QuizSubmission.find(submission_id).report_result!
  end
end
end
