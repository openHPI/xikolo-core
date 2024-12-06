# frozen_string_literal: true

class ImplicitTagDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
        name:,
        course_id:,
        learning_room_id:,
        type: 'Xikolo::Pinboard::ImplicitTag',
        referenced_resource:,
    }.as_json(opts)
  end
end
