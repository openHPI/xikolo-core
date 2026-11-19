# frozen_string_literal: true

class AnswerCreateJob < ApplicationJob
  queue_as :low

  def perform(payload)
    Gamification::Rules::Pinboard::AnsweredQuestion.new(payload).create_score!
  end
end
