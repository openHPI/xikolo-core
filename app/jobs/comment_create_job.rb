# frozen_string_literal: true

class CommentCreateJob < ApplicationJob
  queue_as :low

  def perform(payload)
    Gamification::Rules::Pinboard::CreateComment.new(payload).create_score!
  end
end
