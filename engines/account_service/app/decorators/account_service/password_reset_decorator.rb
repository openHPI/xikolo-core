# frozen_string_literal: true

module AccountService
class PasswordResetDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      user_id: model.user_id,
      id: model.token,
      self_url:,
    }.as_json(opts)
  end

  private

  def self_url
    h.password_reset_url model.token
  end
end
end
