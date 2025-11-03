# frozen_string_literal: true

require 'spec_helper'

describe 'Sessions: Masquerade', type: :request do
  let(:api) { Restify.new(account_service_url).get.value! }
  let(:record) { create(:'account_service/session') }
  let(:session) { api.rel(:session).get({id: record}).value! }

  describe 'PUT masquerade' do
    subject(:response) { session.rel(:masquerade).post({user: user.id}).value! }

    let(:user) { create(:'account_service/user') }

    it { is_expected.to respond_with :ok }

    it 'masquerades session' do
      response

      sess = session.rel(:self).get.value
      expect(sess['user_id']).to eq user.id
    end

    context 'without user' do
      subject(:response) { session.rel(:masquerade).post.value! }

      it 'raises a client error' do
        expect { response }.to raise_error Restify::ClientError do |error|
          expect(error.status).to eq :unprocessable_content
          expect(error.errors).to eq 'user' => %w[required]
        end
      end
    end

    describe '#permissions' do
      subject(:response) { session.rel(:self).get({embed: 'permissions'}).value! }

      let(:role)   { create(:'account_service/role') }
      let(:record) { create(:'account_service/session', masquerade: user) }

      before { create(:'account_service/grant', principal: user, role:, context: AccountService::Context.root) }

      it 'responds with permissions of masqueraded user' do
        expect(response['permissions']).to match_array role.permissions
      end
    end
  end

  describe 'DELETE masquerade' do
    subject(:response) { session.rel(:masquerade).delete.value! }

    let(:user) { create(:'account_service/user') }

    before { record.masquerade! user }

    it { is_expected.to respond_with :ok }

    it 'de-masquerades session' do
      expect { response }.to change {
        session.rel(:self).get.value['user_id']
      }.from(user.id).to(record.user.id)
    end
  end
end
