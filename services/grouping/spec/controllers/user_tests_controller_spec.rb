# frozen_string_literal: true

require 'spec_helper'

describe UserTestsController, type: :controller do
  let(:default_params) { {format: 'json'} }
  let(:valid_attributes) { build(:user_test, identifier: 'user_test').attributes }
  let(:user_id) { '00000001-3100-4444-9999-000000000003' }

  describe 'GET index' do
    subject { json }

    let!(:user_test) { UserTest.create! valid_attributes }
    let(:params) { {} }
    let(:action) { get :index, params: }
    let(:group) { 1 }

    context 'filter by identifier' do
      let(:params) { {identifier: user_test.identifier} }

      before do
        create(:user_test, identifier: 'user_test_2')

        action
      end

      its(:size) { is_expected.to eq 1 }

      it 'returns the requested user_test' do
        expect(json.first['identifier']).to eq user_test.identifier
      end

      context 'for non-existent identifier' do
        let(:params) { {identifier: 'non-existent_identifier'} }

        it { is_expected.to be_empty }
      end
    end

    describe 'ordering' do
      let(:common_start_date) { 2.weeks.ago }
      let!(:recent_user_test_ended) { create(:user_test, start_date: common_start_date, end_date: 2.days.ago) }
      let!(:old_user_test) { create(:user_test, start_date: 2.years.ago) }
      let!(:recent_user_test) { create(:user_test, start_date: common_start_date, end_date: 1.week.from_now) }

      before { action }

      it 'returns all experiments ordered by start date, most recent first' do
        expect(json.pluck('id')).to eq [
          user_test.id,
          recent_user_test.id,
          recent_user_test_ended.id,
          old_user_test.id,
        ]
      end
    end
  end

  describe 'GET show' do
    subject { json }

    let(:action) { get :show, params: }

    it 'renders the requested test as @test' do
      test = create(:user_test)
      get :show, params: {id: test.to_param}
      expect(json['id']).to eq test.id
    end

    it 'responds with 404 Not Found for non-existent resource' do
      get :show, params: {id: SecureRandom.uuid}
      expect(response).to have_http_status :not_found
    end

    it 'responds with 500 Internal Server Error if another error occurs' do
      allow(UserTest).to receive(:find).and_raise StandardError
      get :show, params: {id: SecureRandom.uuid}
      expect(response).to have_http_status :internal_server_error
    end

    context 'params' do
      let!(:user_test) { create(:user_test) }
      let(:params) { {id: user_test.id} }

      before { action }

      context 'with statistics' do
        let(:params) { super().merge(statistics: 'true') }

        its(:keys) do
          is_expected.to match_array \
            %w[id name identifier description start_date end_date
               max_participants course_id metric_ids created_at updated_at
               total_count finished_count waiting_count finished round_robin mean
               test_groups_url metrics_url filters_url required_participants]
        end
      end

      context 'without params' do
        its(:keys) do
          is_expected.to match_array \
            %w[id name identifier description start_date end_date max_participants
               course_id metric_ids created_at updated_at finished round_robin test_groups_url
               metrics_url filters_url]
        end
      end

      context 'with export' do
        let(:params) { super().merge(export: 'true') }

        its(:keys) do
          is_expected.to match_array \
            %w[id name identifier description start_date end_date
               max_participants course_id metric_ids created_at updated_at
               finished round_robin test_groups_url metrics_url filters_url csv]
        end

        context 'csv' do
          subject { super()['csv'].split("\n").first }

          let(:user_test) { create(:user_test_w_waiting_metric_and_results) }

          it { is_expected.to eq 'id,waiting,result,created_at,updated_at,metric,user_id,test_group' }
        end
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'updates the requested test' do
        test = UserTest.create! valid_attributes
        # Assuming there are no other user tests in the database, this
        # specifies that the UserTest created on the previous line
        # receives the update message with whatever params are
        # submitted in the request.
        expect do
          put :update, params: {id: test.to_param, 'name' => 'MyString'}
        end.to change { test.reload.name }.to('MyString')
      end

      it 'updates the requested test metrics' do
        test = UserTest.create! valid_attributes
        test.metrics << create(:metric)
        put :update, params: {id: test.to_param, metrics: [{id: test.metrics.first.id, type: 'PinboardActivity'}]}
        expect(UserTest.first.metrics.first.type).to eq 'PinboardActivity'
      end
    end

    describe 'with invalid params' do
      it 'responds with 422 Unprocessable Entity' do
        test = UserTest.create! valid_attributes
        put :update, params: {id: test.to_param, name: ''}
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested test' do
      test = UserTest.create! valid_attributes
      expect do
        delete :destroy, params: {id: test.to_param}
      end.to change(UserTest, :count).by(-1)
    end
  end
end
