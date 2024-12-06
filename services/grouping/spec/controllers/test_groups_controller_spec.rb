# frozen_string_literal: true

require 'spec_helper'

describe TestGroupsController, type: :controller do
  let(:default_params) { {format: 'json'} }
  let(:user_id) { '00000001-3100-4444-9999-000000000003' }
  let(:user_test) { build(:user_test_w_test_groups) }
  let(:test_group) { build(:test_group_1) }
  let(:valid_attributes) { test_group.attributes.merge attributes_for :test_group }

  before do
    Stub.request(
      :account, :post, '/groups',
      body: {name: test_group.group_name}
    )
  end

  describe 'GET index' do
    subject { json }

    let!(:test_group) { create(:test_group) }
    let(:user_test_2) { create(:user_test_with_waiting_metric, identifier: 'test') }
    let(:test_groups) { create_list(:test_group_w_waiting_seq, 2, user_test: user_test_2) }
    let(:params) { {} }
    let(:action) { get :index, params: }

    before { action }

    it 'renders all test groups' do
      expect(json.pluck('id')).to contain_exactly(test_group.id)
    end

    context 'filter for user test' do
      let(:params) { {user_test_id: test_group.user_test_id} }

      before { test_groups }

      it 'renders the correct test groups' do
        expect(json.pluck('id')).to contain_exactly(test_group.id)
      end
    end

    context 'statistics' do
      subject { json.first }

      context 'with statistics' do
        let(:params) { super().merge(statistics: 'true') }

        its(:keys) do
          is_expected.to match_array \
            %w[id name description flippers ratio index group_id user_test_id
               total_count finished_count waiting_count mean change control
               confidence effect_size box_plot_data required_participants]
        end
      end

      context 'without statistics' do
        its(:keys) do
          is_expected.to match_array \
            %w[id name description flippers ratio index group_id user_test_id]
        end
      end
    end
  end

  describe 'GET show' do
    it 'renders the requested test group' do
      test_group = TestGroup.create! valid_attributes
      get :show, params: {id: test_group.to_param}
      expect(json['id']).to eq(test_group.id)
    end
  end
end
