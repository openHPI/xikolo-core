# frozen_string_literal: true

class AnswerAcceptedJob < ApplicationJob
  queue_as :low

  def perform(payload)
    Gamification::Rules::Pinboard::AcceptedAnswer.new(payload).create_score!
  end
end
