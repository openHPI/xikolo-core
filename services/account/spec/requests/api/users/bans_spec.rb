# frozen_string_literal: true

require 'spec_helper'

describe 'Bans: Create', type: :request do
  subject(:ban_user) { api.rel(:user_ban).post({}, params: {user_id: user.id}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:user) { create(:user) }

  describe 'POST /bans' do
    before { create(:session, user:) }

    it 'responds with 201 Created' do
      expect(ban_user).to respond_with :created
    end

    it 'archives the user' do
      expect { ban_user }.to change { user.reload.archived }.from(false).to(true)
    end

    it 'removes all user sessions' do
      expect { ban_user }.to change(Session, :count).from(1).to(0)
    end

    context 'the user has no sessions' do
      before { user.sessions.destroy_all }

      it 'still archives the user' do
        expect(Session.count).to be_zero
        expect { ban_user }.to change { user.reload.archived }.from(false).to(true)
      end
    end

    context 'the user has been already banned' do
      before { user.ban! }

      it 'responds with 201 Created' do
        expect(ban_user).to respond_with :created
      end

      it 'leaves the user banned' do
        expect { ban_user }.not_to change { user.reload.archived }.from(true)
      end
    end

    context 'the user does not exist' do
      subject(:ban_user) { api.rel(:user_ban).post({}, params: {user_id: 'non-existing'}).value! }

      it 'responds with 404 Not Found' do
        expect { ban_user }.to raise_error(Restify::NotFound) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end
  end
end
