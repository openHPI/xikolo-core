# frozen_string_literal: true

module AccountService
class PolicyDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id: object.id,
      version: object.version,
      url: object.url,
    }.as_json(opts)
  end
end
end
