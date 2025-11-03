# frozen_string_literal: true

module AccountService
class PreferencesDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  def as_json(opts = {})
    {
      user_id: model.id,
      properties: model.preferences,
    }.as_json(opts)
  end
end
end
