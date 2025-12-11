# frozen_string_literal: true

module QuizService
module Regrading # rubocop:disable Layout/IndentationWidth
  class UpdateAllQuestions < Base
    # rubocop:disable Lint/MissingSuper
    def initialize(quiz, dry: false)
      @quiz = quiz

      @dry = dry
    end
    # rubocop:enable Lint/MissingSuper

    # rubocop:disable Rails/SkipsModelValidations
    def run!
      transaction(dry: @dry) do
        log "regrading started... \n", :info
        log 'Reset points for all questions in quiz', :info

        # for all questions, reset points
        QuizSubmissionQuestion.where(quiz_question_id: @quiz.questions).update_all(points: nil, updated_at: time_now)
        log "set points for submitted questions to nil quiz_id: #{@quiz.id}", :info

        # reset quiz_version of submission to newest
        @quiz.submissions.update_all(quiz_version_at: time_now, updated_at: time_now)
        log "updated quiz_version_at to #{time_now} for submissions quiz_id: #{@quiz.id} ", :info

        log "..regrading finished: #{@quiz.submissions.count} submissions regraded \n", :info
      end
      @quiz.questions.each {|question| UpdateQuestionStatisticsWorker.perform_async(question.id) }
    end
    # rubocop:enable all

    private

    def time_now
      @time_now ||= Time.now.utc
    end
  end
end
end
