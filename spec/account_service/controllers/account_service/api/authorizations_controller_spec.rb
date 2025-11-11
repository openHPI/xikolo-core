# frozen_string_literal: true

require 'spec_helper'

describe AccountService::API::AuthorizationsController, type: :controller do
  include_context 'account_service API controller'
  let(:record) { create(:'account_service/authorization') }
  let(:records) { create_list(:'account_service/authorization', 10, expires_at: Time.zone.now) }

  describe '#index' do
    subject(:response) { get :index, params: }

    let(:base) { 'http://test.host/authorizations' }
    let(:params) { {} }
    let(:json) { JSON.parse response.body }

    it_behaves_like 'a paginated action'

    context 'default' do
      before { records }

      it 'contain authorization objects' do
        expect(json).to match_array AccountService::AuthorizationDecorator
          .decorate_collection(records)
          .map {|a| a.as_json(api_version: 1) }
      end
    end

    context 'when filtering by user' do
      let(:user) { records[6].user }
      let(:params) { {user: user.id} }

      it 'contains only given users authorizations' do
        expect(json.pluck('user_id')).to eq [user.id]
      end
    end

    context 'when filtering by UID' do
      let(:uid) { records[3].uid }
      let(:params) { {uid:} }

      it 'contains only the authorization with the given UID' do
        expect(json).to match [hash_including('uid' => uid)]
      end
    end
  end

  describe '#update' do
    subject(:response) { put :update, params: }

    let(:user) { create(:'account_service/user') }
    let(:params) { {id: record.id, user_id: user.id} }

    it { expect(response).to have_http_status :ok }

    it 'updates the user_id' do
      expect { response }
        .to change { record.reload.user_id }.from(record.user_id).to(user.id)
    end

    it 'invokes authorization provider' do
      expect(AccountService::Provider).to receive(:update).with(record)
      response
    end
  end

  describe '#create' do
    subject(:response) { post :create, params: }

    let(:params) { attributes_for(:'account_service/authorization', info: {'hash' => 'true'}) }

    it 'creates new authorization record' do
      expect { response }.to change(AccountService::Authorization, :count).from(0).to(1)
    end

    describe 'created record' do
      subject(:record) { response; AccountService::Authorization.last }

      describe '#info' do
        subject { record.info }

        it { is_expected.to eq params[:info] }
      end
    end
  end
end
