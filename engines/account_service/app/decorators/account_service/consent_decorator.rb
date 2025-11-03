# frozen_string_literal: true

module AccountService
class ConsentDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  DEFAULT = %i[
    name
    required
    consented
  ].freeze

  LINKS = %i[
    self_url
  ].freeze

  def as_json(opts = {})
    export(DEFAULT, optional_fields, LINKS, **opts)
  end

  delegate :id, :name, :required, to: :'model.treatment'

  def consented_at
    super.iso8601
  end

  def optional_fields
    [].tap do |fields|
      fields << :consented_at unless consented.nil?
      fields << :external_consent_url if external_consent_url
    end
  end

  def external_consent_url
    treatment.consent_manager['consent_url']
  end

  def self_url
    h.user_consent_rfc6570.partial_expand \
      user_id: user.to_param,
      id: treatment.to_param
  end

  def user_url
    h.user_rfc6570.partial_expand \
      id: user.to_param
  end

  def treatment_url
    h.treatment_rfc6570.partial_expand \
      id: treatment.to_param
  end
end
end
