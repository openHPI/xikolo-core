# frozen_string_literal: true

class AuthorizationDecorator < Draper::Decorator
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
