# frozen_string_literal: true

module AccountService
class UserDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  DEFAULT = %i[
    id
    password_digest

    name
    full_name
    display_name

    admin
    archived
    affiliated
    affiliation
    confirmed
    anonymous

    email
    born_at
    avatar_url
    accepted_policy_version
    policy_accepted
    timezone

    language
    preferred_language

    created_at
    updated_at

    country
    state
    city
    gender
    status
  ].freeze

  LINKS = %i[
    self_url
    email_url
    emails_url
    features_url
    flippers_url
    groups_url
    permissions_url
    preferences_url
    profile_url
    consents_url
  ].freeze

  def born_at
    super&.iso8601
  end

  def created_at
    super.iso8601
  end

  def updated_at
    super.iso8601
  end

  def as_json(opts = {})
    export DEFAULT, LINKS, **opts
  end

  def as_event(**)
    export(DEFAULT, **)
  end

  def preferred_language
    object.language
  end

  def admin
    false
  end

  def self_url
    h.user_url to_param
  end

  def email_url
    h.user_email_rfc6570.partial_expand user_id: to_param
  end

  def emails_url
    h.user_emails_url to_param
  end

  def features_url
    h.user_features_rfc6570.partial_expand user_id: to_param
  end
  alias flippers_url features_url

  def groups_url
    h.groups_url user: self
  end

  def permissions_url
    h.user_permissions_rfc6570.partial_expand user_id: to_param
  end

  def preferences_url
    h.user_preferences_url to_param
  end

  def profile_url
    h.user_profile_url to_param
  end

  def consents_url
    h.user_consents_rfc6570.partial_expand(user_id: to_param)
  end

  def language
    object.language.presence || Xikolo.config.locales['default']
  end
end
end
