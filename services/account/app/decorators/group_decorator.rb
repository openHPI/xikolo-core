# frozen_string_literal: true

class GroupDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    {
      url: self_url,
      name:,
      description: description.to_s,
      members_url:,
      memberships_url:,
      flippers_url: features_url,
      features_url:,
      grants_url:,
      stats_url:,
      profile_field_stats_url:,
    }.as_json(opts)
  end

  def self_url
    h.group_url self
  end

  def members_url
    h.group_members_url group_id: to_param
  end

  def memberships_url
    h.group_memberships_url group_id: to_param
  end

  def features_url
    h.group_features_rfc6570.partial_expand group_id: to_param
  end

  def grants_url
    h.group_grants_url group_id: to_param
  end

  def stats_url
    h.group_stats_url group_id: to_param
  end

  def profile_field_stats_url
    h.group_profile_field_stats_rfc6570.partial_expand group_id: to_param
  end
end
