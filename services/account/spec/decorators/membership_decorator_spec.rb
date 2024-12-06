# frozen_string_literal: true

require 'spec_helper'

describe MembershipDecorator, type: :decorator do
  let(:membership) { create(:membership) }
  let(:decorator) { described_class.new membership }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    it 'serializes resource as JSON' do
      expect(payload).to eq json \
        'url' => membership_path(membership),
        'user' => membership.user.to_param,
        'user_url' => user_path(membership.user),
        'group' => membership.group.to_param,
        'group_url' => group_path(membership.group)
    end
  end
end
