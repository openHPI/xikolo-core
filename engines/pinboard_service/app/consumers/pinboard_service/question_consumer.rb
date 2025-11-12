# frozen_string_literal: true

module PinboardService
class QuestionConsumer < Msgr::Consumer # rubocop:disable Layout/IndentationWidth
  def read_question
    @message.ack
    user_id = payload.fetch(:user_id)
    question_id = payload.fetch(:question_id)
    timestamp = payload.fetch(:timestamp)

    begin
      watch = Watch.find_or_create_by!(user_id:, question_id:)
      if watch.updated_at&.before?(timestamp) || watch.updated_at.nil?
        watch.update updated_at: timestamp
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
end
