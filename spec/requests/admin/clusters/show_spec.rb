# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Clusters: Show', type: :request do
  subject(:show_cluster) do
    get "/admin/clusters/#{cluster.id}", headers:
  end

  let!(:cluster) { create(:cluster, :visible, id: 'level') }
  let(:headers) { {} }

  before do
    create(:classifier, title: 'Beginner', cluster:)
    create(:classifier, title: 'Intermediate', cluster:)
    create(:classifier, title: 'Expert', cluster:)
  end

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { %w[course.cluster.index] }

      it 'lists the cluster and its classifiers' do
        show_cluster
        expect(response).to have_http_status :ok

        expect(response.body).to include('level')
        expect(response.body).to include('Beginner')
        expect(response.body).to include('Intermediate')
        expect(response.body).to include('Expert')
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

      it 'redirects the user' do
        show_cluster
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects the user' do
      show_cluster
      expect(response).to redirect_to root_url
    end
  end
end
