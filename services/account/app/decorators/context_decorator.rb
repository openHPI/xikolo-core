# frozen_string_literal: true

class ContextDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    export(
      :id,
      :parent_id,
      :reference_uri,
      :self_url,
      :parent_url,
      :ascent_url,
      :ancestors_url,
      **opts
    )
  end

  def self_url
    h.context_path self
  end

  def parent_url
    h.context_path parent_id if parent_id.present?
  end

  def ancestors_url
    h.contexts_path ancestors: id
  end

  def ascent_url
    h.contexts_path ascent: id
  end
end
