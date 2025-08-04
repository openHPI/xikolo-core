# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Classifiers: Update', type: :request do
  subject(:update_classifier) do
    patch "/admin/clusters/#{classifier.cluster_id}/classifiers/#{classifier.id}",
      params: {classifier: params},
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.cluster.manage] }
  let(:classifier) { create(:classifier, attrs) }
  let(:attrs) { attributes_for(:classifier) }
  let(:params) do
    attrs.merge(translations: {
      'en' => 'Classifier #1',
      'de' => 'Klassifikation #1',
    })
  end

  before { stub_user_request permissions: }

  context 'when updating title translations' do
    it 'updates the classifier and redirects to the cluster show view' do
      expect { update_classifier }.to change { classifier.reload.translations }
        .from(attrs[:translations])
        .to({'en' => 'Classifier #1', 'de' => 'Klassifikation #1'})
      expect(response).to redirect_to admin_cluster_path(classifier.cluster)
      expect(flash[:success].first).to eq 'The tag has been updated.'
    end
  end

  context 'when updating description translations' do
    let(:params) { attrs.merge(descriptions: {'de' => 'Klassifikationsbeschreibung #1'}) }

    it 'updates the classifier and redirects to the cluster show view' do
      expect { update_classifier }.to change { classifier.reload.descriptions }
        .from(attrs[:descriptions])
        .to({'de' => 'Klassifikationsbeschreibung #1'})
      expect(response).to redirect_to admin_cluster_path(classifier.cluster)
      expect(flash[:success].first).to eq 'The tag has been updated.'
    end
  end

  context 'with changed title' do
    let(:params) { attrs.merge(title: 'New Tag') }

    it 'does not update the title' do
      expect { update_classifier }.not_to change { classifier.reload.title }.from(attrs[:title])
      expect(response).to redirect_to admin_cluster_path(classifier.cluster)
      expect(flash[:success].first).to eq 'The tag has been updated.'
    end
  end

  context 'with a blank english translation' do
    let(:params) { super().merge translations: {'de' => 'Klassifikation #1'} }

    it 'displays an error message' do
      expect { update_classifier }.not_to change { classifier.reload.translations }
      expect(response.body).to render_template :edit
      expect(flash[:error].first).to eq 'The tag was not updated.'
    end
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'redirects to the homepage' do
      update_classifier
      expect(response).to redirect_to root_path
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      update_classifier
      expect(response).to redirect_to 'http://www.example.com/'
    end
  end
end
