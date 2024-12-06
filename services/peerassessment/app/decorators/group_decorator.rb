# frozen_string_literal: true

class GroupDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      participants:,
    }.as_json(opts)
  end
end
