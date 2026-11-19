# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Classifiers: Destroy', type: :request do
  subject(:destroy_classifier) do
    delete "/admin/clusters/#{cluster.id}/classifiers/#{classifier.id}"
  end

  let(:cluster) { create(:cluster, :visible, id: 'level') }
  let!(:classifier) { create(:classifier, cluster:) }
  let(:user) { create(:'account_service/user', :admin) }

  context 'for logged-in users' do
    before { sign_in(user:) }

    it 'deletes the classifier' do
      expect { destroy_classifier }.to change(CourseService::Classifier, :count).from(1).to(0)
      expect(response).to redirect_to admin_cluster_url(classifier.cluster)
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

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
