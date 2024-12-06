# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Cluster: ClassifiersOrder: Update', type: :request do
  let(:update_order) do
    post "/admin/clusters/#{cluster.id}/classifiers/order", params:, headers:
  end
  let(:headers) { {} }
  let(:params) { {} }
  let(:cluster) { create(:cluster, :order_automatic) }
  let(:classifiers) do
    [
      create(:classifier, title: 'A', position: 1, cluster:),
      create(:classifier, title: 'B', position: 2, cluster:),
      create(:classifier, title: 'C', position: 3, cluster:),
    ]
  end

  context 'with permission' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[course.cluster.manage] }

    before { stub_user_request permissions: }

    context 'with valid params' do
      let(:params) do
        {
          classifiers: [
            classifiers[2].id,
            classifiers[0].id,
            classifiers[1].id,
          ],
        }
      end

      it 'updates the cluster to be sorted manually' do
        expect { update_order }.to change { cluster.reload.sort_mode }
          .from('automatic').to('manual')
      end

      it 'updates the classifier order' do
        expect { update_order }.to change {
          classifiers.map {|c| c.reload.position }
        }.from([1, 2, 3]).to([2, 3, 1])
        expect(flash[:success].first).to eq 'The tag order has been updated.'
        expect(update_order).to redirect_to admin_cluster_url(cluster)
      end

      context "with the cluster's classifiers sorted by position" do
        let(:cluster) { create(:cluster, :order_manual) }

        it 'keeps the cluster to be sorted manually' do
          expect { update_order }.not_to change { cluster.reload.sort_mode }
            .from('manual')
        end
      end
    end

    context 'invalid params' do
      let(:params) do
        {
          data: [
            classifiers[2].id,
            classifiers[0].id,
            classifiers[1].id,
          ],
        }
      end

      it 'does not update the classifier order' do
        expect { update_order }.not_to change {
          classifiers.map {|c| c.reload.position }
        }.from([1, 2, 3])
        expect(flash[:error].first).to include 'Something went wrong.'
        expect(update_order).to redirect_to admin_cluster_classifiers_order_url(cluster)
      end
    end
  end

  context 'without permission' do
    it 'redirects to the start page' do
      expect(update_order).to redirect_to root_url
    end
  end
end
