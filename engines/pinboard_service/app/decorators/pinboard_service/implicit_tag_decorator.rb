# frozen_string_literal: true

module PinboardService
class ImplicitTagDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id:,
        name:,
        course_id:,
        type: 'Xikolo::Pinboard::ImplicitTag',
        referenced_resource:,
    }.as_json(opts)
  end
end
end
