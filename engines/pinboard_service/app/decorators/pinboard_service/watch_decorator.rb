# frozen_string_literal: true

module PinboardService
class WatchDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def to_event
    {
      id:,
      user_id:,
      question_id:,
      course_id:,
      created_at:,
      updated_at:,
    }
  end
end
end
