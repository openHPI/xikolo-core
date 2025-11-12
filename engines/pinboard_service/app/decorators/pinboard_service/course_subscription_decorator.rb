# frozen_string_literal: true

module PinboardService
class CourseSubscriptionDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    basic.as_json(opts)
  end

  def basic
    {
      id: id,
      user_id: user_id,
      course_id: course_id,
      created_at: created_at,
    }
  end
end
end
