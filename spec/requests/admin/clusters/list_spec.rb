# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Clusters: List', type: :request do
  subject(:request) { get '/admin/clusters' }

  before do
    cluster = create(:cluster, :visible, :order_automatic, id: 'level')
    create(:classifier, cluster:, title: 'Beginner', translations: {en: 'Beginner'})
    create(:classifier, cluster:, title: 'Intermediate', translations: {en: 'Intermediate'})
    create(:classifier, cluster:, title: 'Expert', translations: {en: 'Expert'})
  end

  context 'as anonymous user' do
    it 'redirects the user' do
      request
      expect(response).to redirect_to root_url
    end
  end

  context 'as logged in user' do
    before { sign_in(user:) }

    let(:user) { create(:'account_service/user') }

    it 'redirects the user' do
      request
      expect(response).to redirect_to root_url
    end

    context 'with permissions' do
      let(:user) { create(:'account_service/user', :admin) }

      it 'lists all clusters and their classifiers' do
        request
        expect(response).to have_http_status :ok

        expect(response.body).to include('level')
        expect(response.body).to include('Beginner, Expert, Intermediate')
      end
    end
  end
end
