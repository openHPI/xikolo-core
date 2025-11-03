# frozen_string_literal: true

module AccountService
class AuthorizationDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id:,
      user_id:,
      provider:,
      uid:,
      token:,
      secret:,
      expires_at: expires_at.try(:iso8601),
      info:,
    }.as_json(opts)
  end
end
end
