# frozen_string_literal: true

class ExplicitTagDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
        name:,
        course_id:,
        learning_room_id:,
        type: 'Xikolo::Pinboard::ExplicitTag',
    }.as_json(opts)
  end
end
