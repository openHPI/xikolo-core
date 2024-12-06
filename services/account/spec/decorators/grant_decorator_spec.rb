# frozen_string_literal: true

require 'spec_helper'

describe GrantDecorator, type: :decorator do
  let(:group) { create(:group) }
  let(:role) { create(:role) }
  let(:grant) { create(:grant, role:, principal: group, context: Context.root) }
  let(:decorator) { described_class.new grant }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    it 'serializes resource as JSON' do
      expect(payload).to eq json \
        'group' => group.name,
        'role' => role.id,
        'role_name' => role.name,
        'self_url' => h.grant_url(grant.id),
        'context' => Context.root_id,
        'context_name' => 'root'
    end
  end
end
