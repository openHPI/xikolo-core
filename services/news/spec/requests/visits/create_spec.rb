# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Visits: Create', type: :request do
  subject(:request) { service.rel(:visits).post(visit_params).value! }

  let(:service) { Restify.new(:test).get.value! }
  let(:visit_params) { {user_id:, announcement_id: announcement.id} }
  let(:user_id) { SecureRandom.uuid }
  let(:announcement) { create(:news) }

  before { announcement }

  context 'when no state exists for the user' do
    it { is_expected.to respond_with :ok }

    it 'creates a new read state' do
      expect { request }.to change {
        announcement.read_states.where(user_id:).count
      }.from(0).to(1)
    end
  end

  context 'when a state exists for the user' do
    let(:announcement) { create(:news, :read, read_by_users: [user_id]) }

    it { is_expected.to respond_with :ok }

    it 'does not create a new read state' do
      expect { request }.not_to change(ReadState, :count)
    end

    it 'updates the existing read state object' do
      expect { request }.to change {
        ReadState.first.updated_at
      }
    end
  end

  context 'when an announcement does not exist anymore' do
    before { announcement.destroy }

    it 'does not create a new read state and returns 404 Not Found' do
      expect { request }.to raise_error Restify::NotFound
      expect(ReadState.count).to eq 0
    end
  end
end
