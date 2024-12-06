# frozen_string_literal: true

class WatchDecorator < Draper::Decorator
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
