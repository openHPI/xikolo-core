# frozen_string_literal: true

module Regrading
  ##
  # Select answer for all users and recalculate points
  #
  class SelectAnswerForAll < Base
    # rubocop:disable Lint/MissingSuper
    def initialize(answer, dry: false)
      @answer = answer

      @dry = dry
    end
    # rubocop:enable Lint/MissingSuper

    # rubocop:disable Rails/SkipsModelValidations
    def run!
      transaction(dry: @dry) do
        log "regrading started... \n", :info
        log 'Select answer for all users and recalculate points', :info

        # get quiz question and quiz
        question = @answer.question

        quiz_id = question.quiz_id

        # determine affected quiz_submission_questions
        query = <<~SQL.squish
          SELECT * FROM quiz_submission_questions
          WHERE quiz_question_id = '#{question.id}'
          AND NOT EXISTS(
            SELECT * FROM quiz_submission_answers
            WHERE quiz_submission_question_id = quiz_submission_questions.id
            AND quiz_answer_id = '#{@answer.id}'
          )
        SQL
        affected_submission_questions = QuizSubmissionQuestion.find_by_sql query
        log "#{affected_submission_questions.count} submissions affected", :info

        count = 0
        affected_submission_questions.each do |submission_question|
          type = if question.type == 'FreeTextQuestion'
                   'QuizSubmissionFreeTextAnswer'
                 else
                   'QuizSubmissionSelectableAnswer'
                 end
          submission_answer = QuizSubmissionAnswer.create(
            quiz_submission_question_id: submission_question.id,
            quiz_answer_id: @answer.id,
            type:,
            created_at: submission_question.created_at,
            updated_at: submission_question.updated_at
          )

          count += 1

          log <<~TEXT.strip, :info
            added submitted answer with id: #{submission_answer.id} \
            quiz_submission_question_id: #{submission_answer.quiz_submission_question_id} \
            quiz_answer_id: #{submission_answer.quiz_answer_id}
          TEXT
        end

        # recalculate points
        # rubocop:disable Style/CombinableLoops
        affected_submission_questions.each do |submission_question|
          submission_question.update(points: nil)
          log <<~TEXT.strip, :info
            set points for submitted question to nil submission_question.id: #{submission_question.id} \
            submission_question.submission_id: #{submission_question.quiz_submission_id} \
            quiz_question.id: #{submission_question.quiz_question_id}
          TEXT
        end
        # rubocop:enable Style/CombinableLoops

        # reset quiz_version of submission to newest
        affected_submissions = QuizSubmission.where(quiz_id:)
        affected_submissions.update_all(quiz_version_at: time_now, updated_at: time_now)
        log "updated quiz_version_at to #{time_now} for submissions with quiz_id: #{quiz_id}", :info

        log "..regrading finished: #{count} submissions regraded \n", :info

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
