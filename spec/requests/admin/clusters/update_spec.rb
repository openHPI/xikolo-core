# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Clusters: Update', type: :request do
  subject(:update_cluster) { patch "/admin/clusters/#{cluster.id}", params: {cluster: params}, headers: }

  let(:cluster) { create(:cluster, :visible, id: 'level', translations: {'de' => 'Themen', 'en' => 'Tropic'}) }
  let(:params) { {translations: {'de' => 'Themen', 'en' => 'Topic'}} }

  let(:headers) { {} }

  context 'as anonymous user' do
    it 'redirects the user' do
      update_cluster
      expect(response).to redirect_to root_url
    end
  end

  context 'as logged in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { [] }

    before { stub_user_request permissions: }

    it 'redirects the user' do
      update_cluster
      expect(response).to redirect_to root_url
    end

    context 'with permissions' do
      let(:permissions) { %w[course.cluster.manage] }

      it 'updates the cluster and redirects to the cluster list' do
        expect { update_cluster }.to change { cluster.reload.translations }
          .from({'de' => 'Themen', 'en' => 'Tropic'})
          .to({'de' => 'Themen', 'en' => 'Topic'})
        expect(response).to redirect_to admin_clusters_path
        expect(flash[:success].first).to eq 'The category has been updated.'
      end

      context 'without the standard platform language' do
        let(:params) { {translations: {'de' => 'Themen'}} }

        it 'displays an error message' do
          expect { update_cluster }.not_to change { cluster.reload.translations }
          expect(response).to render_template :edit
          expect(flash[:error].first).to eq 'The category was not updated.'
        end
      end

      context 'when setting the cluster to hidden' do
        let(:params) { {visible: false} }

        it 'updates the cluster and redirects to the cluster list' do
          expect { update_cluster }.to change { cluster.reload.visible }
            .from(true)
            .to(false)
          expect(response).to redirect_to admin_clusters_path
          expect(flash[:success].first).to eq 'The category has been updated.'
        end
      end
    end
  end
end
