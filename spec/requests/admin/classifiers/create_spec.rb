# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Classifiers: Create', type: :request do
  subject(:create_classifier) do
    post "/admin/clusters/#{cluster.id}/classifiers",
      params: {classifier: params},
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.cluster.manage] }
  let(:cluster) { create(:cluster, :visible, id: 'level') }
  let(:params) do
    {
      title: 'New Tag',
      translations: {'en' => 'My tag', 'de' => 'Mein Tag'},
    }
  end

  before { stub_user_request permissions: }

  it 'creates a new classifier' do
    expect { create_classifier }.to change(Course::Classifier, :count).from(0).to(1)
    expect(Course::Classifier.first).to match an_object_having_attributes(
      cluster_id: cluster.id,
      **params
    )
    expect(response).to redirect_to admin_cluster_path(cluster)
    expect(flash[:success].first).to eq 'The tag has been created.'
  end

  context 'with blank title (ID)' do
    let(:params) { super().merge title: ' ' }

    it 'displays an error message' do
      expect { create_classifier }.not_to change(Course::Classifier, :count).from(0)
      expect(response.body).to render_template :new
      expect(flash[:error].first).to eq 'The tag was not created.'
    end
  end

  context 'without permission to manage classifiers' do
    let(:permissions) { [] }

    it 'redirects to the homepage' do
      create_classifier
      expect(response).to redirect_to root_path
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      create_classifier
      expect(response).to redirect_to 'http://www.example.com/'
    end
  end
end
