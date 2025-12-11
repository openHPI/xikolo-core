# frozen_string_literal: true

module QuizService
class UpdateQuestionStatisticsWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(question_id, enqueued_at = Time.zone.now.to_s)
    question = Question.find(question_id)

    return if question.statistics.present? && question.statistics.updated_at > DateTime.parse(enqueued_at)

    question.update_statistics!
  rescue ActiveRecord::RecordNotFound
    logger.error "Could not find question with id #{question_id}"
  end
end
end
