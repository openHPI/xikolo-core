# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'News User Visit: Update', type: :request do
  subject(:request) { news_resource.rel(:user_visit).patch({}, params: {user_id:}).value! }

  let(:service) { restify_with_headers(news_service_url).get.value! }
  let(:news_resource) { service.rel(:news).get({id: announcement.id}).value! }
  let(:announcement) { create(:'news_service/news') }
  let(:user_id) { SecureRandom.uuid }

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
    let(:announcement) { create(:'news_service/news', :read, read_by_users: [user_id]) }

    it { is_expected.to respond_with :ok }

    it 'does not create a new read state' do
      expect { request }.not_to change(NewsService::ReadState, :count)
    end

    it 'updates the existing read state object' do
      expect { request }.to change {
        NewsService::ReadState.first.updated_at
      }
    end
  end
end
