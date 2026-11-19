# frozen_string_literal: true

class ResultCreateJob < ApplicationJob
  queue_as :low

  def perform(payload)
    # Make sure we have a rule matching the exercise type
    case payload.fetch(:exercise_type)
      when 'main'
        Gamification::Rules::Course::TakeExam.new(payload).create_score!
      when 'selftest'
        Gamification::Rules::Course::TakeSelftest.new(payload).create_score!
    end
  end
end
