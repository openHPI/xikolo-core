# frozen_string_literal: true

class VoteCreateJob < ApplicationJob
  queue_as :low

  def perform(payload)
    # Make sure we have a rule for the votable element
    case payload.fetch(:votable_type)
      when 'Answer'
        Gamification::Rules::Pinboard::UpvoteAnswer.new(payload).create_score!
      when 'Question'
        Gamification::Rules::Pinboard::UpvoteQuestion.new(payload).create_score!
    end
  end
end
