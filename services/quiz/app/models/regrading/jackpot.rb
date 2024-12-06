# frozen_string_literal: true

module Regrading
  class Jackpot < Base
    # rubocop:disable Lint/MissingSuper
    def initialize(question, dry: false)
      @question = question

      @dry = dry
    end
    # rubocop:enable Lint/MissingSuper

    # rubocop:disable Rails/SkipsModelValidations
    def run!
      return if affected.empty? && !submission_gap?

      transaction(dry: @dry) do
        fill_submission_gap!

        log "Total submissions: #{all.count}", :info
        log "Affected submissions: #{affected.count}", :info
        log "Average points before: #{all.average(:points)}", :info

        affected.update_all(points: @question.points, updated_at: time_now)

        log "Average points after: #{all.average(:points)}", :info

        # trigger background worker to recalculate statistics
        UpdateQuestionStatisticsWorker.perform_async(@question.id)
      end
    end
    # rubocop:enable all

    private

    def fill_submission_gap!
      # All submissions have a QuizSubmissionQuestion for this @question? Fine then.
      return unless submission_gap?

      log "Creating missing quiz submission questions: #{submissions.count - all.count}", :info

      # Create missing QuizSubmissionQuestions
      submissions.where.not(id: all.pluck(:quiz_submission_id)).find_each do |sub|
        QuizSubmissionQuestion.create!(quiz_submission_id: sub.id, quiz_question_id: @question.id, points: 0)
      end

      # reset all and affected (force reload)
      @all = nil
      @affected = nil
    end

    def submission_gap?
      all.count != submissions.count
    end

    def all
      @all ||= QuizSubmissionQuestion.where(quiz_question_id: @question.id)
    end

    def affected
      @affected ||= all.where(points: ...@question.points)
    end

    def time_now
      @time_now ||= Time.now.utc
    end

    def submissions
      @submissions ||= QuizSubmission.where(quiz_id: @question.quiz_id)
    end
  end
end
