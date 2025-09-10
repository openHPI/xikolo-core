# frozen_string_literal: true

class CourseSubscriptionDecorator < Draper::Decorator
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
