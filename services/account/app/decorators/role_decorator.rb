# frozen_string_literal: true

class RoleDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    {
      id: model.id,
      name: model.name,
      permissions: model.permissions,
    }.as_json(opts)
  end
end
