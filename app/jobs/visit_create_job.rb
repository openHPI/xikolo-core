# frozen_string_literal: true

class VisitCreateJob < ApplicationJob
  queue_as :low

  def perform(payload)
    Gamification::Rules::Course::VisitedItem.new(payload).create_score!
  end
end
