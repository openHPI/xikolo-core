# frozen_string_literal: true

class PinboardDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      topic:,
        supervised:,
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601,
    }.as_json(opts)
  end
end
