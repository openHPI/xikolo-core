# frozen_string_literal: true

class PreferencesDecorator < Draper::Decorator
  def as_json(opts = {})
    {
      user_id: model.id,
      properties: model.preferences,
    }.as_json(opts)
  end
end
