# frozen_string_literal: true

module PinboardService
class ReadQuestionJob < ApplicationJob # rubocop:disable Layout/IndentationWidth
  queue_as :default

  def perform(user_id, question_id, timestamp)
    watch = Watch.find_or_create_by!(user_id:, question_id:)
    if watch.updated_at&.before?(timestamp) || watch.updated_at.nil?
      watch.update updated_at: timestamp
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
end
