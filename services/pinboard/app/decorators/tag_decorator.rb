# frozen_string_literal: true

class TagDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
        name:,
        course_id:,
        learning_room_id:,
        type: "Xikolo::Pinboard::#{type}",
    }.as_json(opts)
  end
end
