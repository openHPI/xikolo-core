# frozen_string_literal: true

require 'spec_helper'

describe AccountService::GroupDecorator, type: :decorator do
  let(:group) { create(:'account_service/group') }
  let(:decorator) { described_class.new group }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    it 'serializes resource as JSON' do
      expect(payload).to eq json \
        'url' => h.account_service.group_url(group),
        'name' => group.name,
        'description' => group.description.to_s,
        'members_url' => h.account_service.group_members_url(group),
        'memberships_url' => h.account_service.group_memberships_url(group),
        'flippers_url' => h.account_service.group_features_rfc6570.partial_expand(group_id: group.to_param),
        'features_url' => h.account_service.group_features_rfc6570.partial_expand(group_id: group.to_param),
        'grants_url' => h.account_service.group_grants_url(group),
        'stats_url' => h.account_service.group_stats_url(group),
        'profile_field_stats_url' => h.account_service.group_profile_field_stats_rfc6570.partial_expand(group_id: group.to_param)
    end
  end
end
