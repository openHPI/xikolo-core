# frozen_string_literal: true

module QuizService
module Regrading # rubocop:disable Layout/IndentationWidth
  class UpdateCourseResults < Base
    def initialize(logger, quiz_id)
      super(logger)

      @quiz_id = quiz_id
    end

    def run!
      quiz_id = @quiz_id
      log "Update course results for previous manual regrading quiz_id: #{quiz_id} \n", :info

      submissions = QuizSubmission
        .where.not(quiz_submission_time: nil)
        .where(quiz_id:)

      total = submissions.count

      submissions = submissions.includes(:quiz_submission_questions)
      submissions.each_with_index do |submission, i|
        log "#{i + 1}/#{total} results updated", :info

        reporter.report! submission
      end

      log 'Updated course results', :info
    end

    def reporter
      @reporter ||= ResultReporter.new(@quiz_id)
    end
  end
end
end
