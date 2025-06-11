# frozen_string_literal: true

require 'spec_helper'

describe 'Classifiers: Show', type: :request do
  subject(:request) { get '/app/classifiers', params:, headers: }

  let(:headers) { {} }
  let(:params) { {} }
  let(:user) { create(:user) }

  let(:cluster1) { create(:cluster, id: 1) }
  let(:cluster2) { create(:cluster, id: 2) }
  let!(:classifier1) { create(:classifier, title: 'Alpha', cluster_id: 1, translations: {'en' => 'Alpha'}, cluster: cluster1) }
  let!(:classifier2) { create(:classifier, title: 'Beta', cluster_id: 2, translations: {'en' => 'Beta'}, cluster: cluster2) }

  before do
    stub_user_request id: user.id
    Stub.service(:account, build(:'account:root'))
    Stub.request(:account, :get, '/sessions/')
      .and_return Stub.json(build(:'account:session', user_id: user.id))
  end

  context 'when not logged in' do
    it 'returns unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  context 'when logged in' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    it 'returns all classifiers' do
      request
      expect(response).to have_http_status :ok
      body = response.parsed_body
      expect(body['classifiers'].size).to eq(2)
      expect(body['classifiers'].map {|c| c['id'] }).to contain_exactly(classifier1.id, classifier2.id)
    end

    context 'with cluster filter' do
      let(:params) { {cluster: 1} }

      it 'returns classifiers for the given cluster' do
        request
        body = response.parsed_body
        expect(body['classifiers'].size).to eq(1)
        expect(body['classifiers'].first['id']).to eq(classifier1.id)
      end
    end

    context 'with search query' do
      let(:params) { {q: 'Alpha'} }

      it 'returns classifiers matching the query' do
        request
        body = response.parsed_body
        expect(body['classifiers'].size).to eq(1)
        expect(body['classifiers'].first['id']).to eq(classifier1.id)
      end
    end
  end
end
