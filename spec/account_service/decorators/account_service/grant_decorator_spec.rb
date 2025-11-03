# frozen_string_literal: true

require 'spec_helper'

describe AccountService::GrantDecorator, type: :decorator do
  let(:group) { create(:'account_service/group') }
  let(:role) { create(:'account_service/role') }
  let(:grant) { create(:'account_service/grant', role:, principal: group, context: AccountService::Context.root) }
  let(:decorator) { described_class.new grant }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    it 'serializes resource as JSON' do
      expect(payload).to eq json \
        'group' => group.name,
        'role' => role.id,
        'role_name' => role.name,
        'self_url' => h.account_service.grant_url(grant.id),
        'context' => AccountService::Context.root_id,
        'context_name' => 'root'
    end
  end
end
