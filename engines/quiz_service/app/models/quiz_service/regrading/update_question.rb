# frozen_string_literal: true

module QuizService
module Regrading # rubocop:disable Layout/IndentationWidth
  class UpdateQuestion < Base
    # rubocop:disable Lint/MissingSuper
    def initialize(question, dry: false)
      @question = question

      @dry = dry
    end
    # rubocop:enable Lint/MissingSuper

    # rubocop:disable Rails/SkipsModelValidations
    def run!
      transaction(dry: @dry) do
        log "regrading started... \n", :info
        log 'Reset points for question', :info

        # reset points
        QuizSubmissionQuestion.where(quiz_question_id: @question.id).update_all(points: nil, updated_at: time_now)
        log "set points for submitted questions to nil quiz_question.id: #{@question.id}", :info

        # reset quiz_version of submission to newest
        affected_submissions = QuizSubmission.where(quiz_id: @question.quiz_id)
        affected_submissions.update_all(quiz_version_at: time_now, updated_at: time_now)
        log "updated quiz_version_at to #{time_now} for submissions with quiz_id: #{@question.quiz_id} ", :info

        log "..regrading finished: #{affected_submissions.count} submissions regraded \n", :info

        # trigger background worker to recalculate statistics
        UpdateQuestionStatisticsWorker.perform_async(@question.id)
      end
    end
    # rubocop:enable all

    private

    def time_now
      @time_now ||= Time.now.utc
    end
  end
end
end
