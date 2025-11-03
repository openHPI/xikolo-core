# frozen_string_literal: true

module AccountService
class TokenDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id: model.id,
      user_id: model.user_id,
      token: model.token,
    }.as_json(opts)
  end
end
end
