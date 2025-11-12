# frozen_string_literal: true

module PinboardService
class TagDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id:,
        name:,
        course_id:,
        type: "Xikolo::Pinboard::#{type}",
    }.as_json(opts)
  end
end
end
