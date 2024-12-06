# frozen_string_literal: true

class GrantDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    {
      context: model.context_id,
      context_name:,
      role: model.role_id,
      role_name: model.role.name,
      self_url: h.grant_url(model.id),
    }.tap do |attrs|
      attrs[:group] = model.principal.name if model.principal.is_a? Group
    end.as_json(opts)
  end

  def context_name
    'root' if model.context_id == Context.root_id
  end
end
