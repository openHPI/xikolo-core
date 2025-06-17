# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Ajax: Classifiers: Index', type: :request do
  subject(:request) { get '/admin/find_classifiers', params:, headers: }

  let(:headers) { {} }
  let(:params) { {} }
  let(:user) { create(:user) }
  let(:permissions) { [] }

  let!(:classifier1) { create(:classifier, title: 'Alpha', cluster_id: 1, translations: {'en' => 'Alpha'}, cluster: create(:cluster, id: 1)) }
  let!(:classifier2) { create(:classifier, title: 'Beta', cluster_id: 2, translations: {'en' => 'Beta'}, cluster: create(:cluster, id: 2)) }

  let(:json) { response.parsed_body }

  before do
    stub_user_request id: user.id
    stub_user_request(permissions:)

    Stub.service(:account, build(:'account:root'))
    Stub.request(:account, :get, '/sessions/')
      .and_return Stub.json(build(:'account:session', user_id: user.id))
  end

  context 'when not logged in' do
    it 'responds with Forbidden' do
      request
      expect(response).to have_http_status :forbidden
    end
  end

  context 'when logged in' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    context 'without permissions' do
      it 'responds with Forbidden' do
        request
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with permissions' do
      let(:permissions) { ['course.course.edit'] }

      it 'returns all classifiers' do
        request
        expect(response).to have_http_status :ok
        expect(json.size).to eq(2)
        expect(json.map {|c| c['id'] }).to contain_exactly(classifier1.id, classifier2.id)
      end

      context 'with cluster filter' do
        let(:params) { {cluster: 1} }

        it 'returns classifiers for the given cluster' do
          request
          expect(json.size).to eq(1)
          expect(json.first['id']).to eq(classifier1.id)
        end
      end

      context 'with search query' do
        let(:params) { {q: 'Alpha'} }

        it 'returns classifiers matching the query' do
          request
          expect(json.size).to eq(1)
          expect(json.first['id']).to eq(classifier1.id)
        end
      end
    end
  end
end
