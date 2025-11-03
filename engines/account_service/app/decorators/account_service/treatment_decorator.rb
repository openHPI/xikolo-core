# frozen_string_literal: true

module AccountService
class TreatmentDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  DEFAULT = %i[
    name
    required
    consent_manager
  ].freeze

  LINKS = %i[
    self_url
  ].freeze

  def as_json(opts = {})
    export DEFAULT, LINKS, **opts
  end

  protected

  def self_url
    h.treatment_url(model)
  end
end
end
