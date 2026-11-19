# frozen_string_literal: true

class QuestionCreateJob < ApplicationJob
  queue_as :low

  def perform(payload)
    Gamification::Rules::Pinboard::CreateQuestion.new(payload).create_score!
  end
end
