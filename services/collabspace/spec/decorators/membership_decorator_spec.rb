# frozen_string_literal: true

require 'spec_helper'

describe MembershipDecorator, type: :decorator do
  let(:membership) { described_class.new create(:membership) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { membership.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('user_id') }
    it { is_expected.to include('collab_space_id') }
    it { is_expected.to include('status') }
    it { is_expected.to include('collab_space_url') }
  end
end
