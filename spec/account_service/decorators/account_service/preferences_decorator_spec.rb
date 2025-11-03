# frozen_string_literal: true

require 'spec_helper'

describe AccountService::PreferencesDecorator, type: :decorator do
  let(:user) { create(:'account_service/user') }
  let(:decorator) { described_class.new user }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    before do
      user.update! preferences: {'key' => true}
    end

    it 'includes the correct properties' do
      expect(payload.keys).to match_array %w[
        user_id
        properties
      ]
    end

    it { expect(payload['user_id']).to eq user.id }
    it { expect(payload['properties']).to be_a Hash }
    it { expect(payload['properties']).to include 'key' }
    it { expect(payload['properties']['key']).to eq 'true' }
  end
end
