# frozen_string_literal: true

class RubricOptionDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      rubric_id:,
      description:,
      points:,
    }.as_json(opts)
  end
end
