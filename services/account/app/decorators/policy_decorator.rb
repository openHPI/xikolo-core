# frozen_string_literal: true

class PolicyDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id: object.id,
      version: object.version,
      url: object.url,
    }.as_json(opts)
  end
end
