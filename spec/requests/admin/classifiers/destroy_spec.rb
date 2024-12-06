# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Classifiers: Destroy', type: :request do
  subject(:destroy_classifier) do
    delete "/admin/clusters/#{cluster.id}/classifiers/#{classifier.id}",
      headers:
  end

  let(:headers) { {} }
  let(:cluster) { create(:cluster, :visible, id: 'level') }
  let!(:classifier) { create(:classifier, cluster:) }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { %w[course.cluster.manage] }

      it 'deletes the classifier' do
        expect { destroy_classifier }.to change(Course::Classifier, :count).from(1).to(0)
        expect(response).to redirect_to admin_cluster_url(classifier.cluster)
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

      it 'redirects the user' do
        destroy_classifier
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects the user' do
      destroy_classifier
      expect(response).to redirect_to root_url
    end
  end
end
