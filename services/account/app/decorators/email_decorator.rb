# frozen_string_literal: true

class EmailDecorator < ApplicationDecorator
  delegate_all
  def as_json(opts = {})
    {
      id: model.uuid,
      user_id: model.user_id,
      address: model.address,
      primary: model.primary,
      confirmed: model.confirmed,
      confirmed_at: model.confirmed_at.try(:iso8601),
      created_at: model.created_at.iso8601,
      user_url: h.user_url(model.user_id),
      suspension_url: h.user_email_suspension_url(model.user_id, model.uuid),
      self_url: h.user_email_url(model.user_id, model.uuid),
    }.as_json(opts)
  end
end
