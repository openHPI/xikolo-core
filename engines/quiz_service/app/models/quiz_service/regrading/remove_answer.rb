# frozen_string_literal: true

module QuizService
module Regrading # rubocop:disable Layout/IndentationWidth
  ##
  # Remove answer from question and recalculate points from remaining answers
  #
  class RemoveAnswer < Base
    # rubocop:disable Lint/MissingSuper
    def initialize(answer, dry: false)
      @answer = answer

      @dry = dry
    end
    # rubocop:enable Lint/MissingSuper

    # rubocop:disable Rails/SkipsModelValidations
    def run!
      transaction(dry: @dry) do
        question = @answer.question
        quiz_id = question.quiz_id

        @answer.destroy
        log "deleted answer with id: #{@answer.id} for question: #{question.id} in quiz: #{quiz_id}", :info

        # delete answer from quiz submission
        QuizSubmissionAnswer.where(quiz_answer_id: @answer.id).in_batches.destroy_all
        log "deleted submitted answers with quiz_answer_id: #{@answer.id}", :info

        # recalculate points from selected answers
        log 'Try to update points for all questions', :info
        QuizSubmissionQuestion.where(quiz_question_id: question.id).update_all(points: nil, updated_at: time_now)
        log "set points for submitted question to nil quiz_question.id: #{question.id}", :info

        # reset quiz_version of submission to newest
        affected_submissions = QuizSubmission.where(quiz_id:)
        affected_submissions.update_all(quiz_version_at: time_now, updated_at: time_now)
        log "updated quiz_version_at to #{time_now} for all submissions for quiz_id: #{quiz_id} ", :info

        log "..regrading finished: #{affected_submissions.count} submissions regraded \n", :info

        # trigger background worker to recalculate statistics
        UpdateQuestionStatisticsWorker.perform_async(question.id)
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
