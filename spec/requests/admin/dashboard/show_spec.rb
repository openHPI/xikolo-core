# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Dashboard: Show', type: :request do
  subject(:action) { get('/admin/dashboard', headers:) }

  let(:headers) { {} }
  let(:permissions) { [] }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['global.dashboard.show'] }

      before do
        allow(Admin::Statistics::AgeDistribution).to receive(:call).and_return([])

        Stub.request(:account, :get, '/statistic')
          .to_return Stub.json({
            'confirmed_users' => 0,
            'confirmed_users_last_day' => 0,
            'users_deleted' => 0,
          })
        Stub.request(:course, :get, '/stats?key=global')
          .to_return Stub.json({
            'platform_enrollments' => 0,
            'platform_enrollment_delta_sum' => 0,
            'platform_last_day_enrollments' => 0,
            'courses_count' => 0,
          })

        Stub.service(:learnanalytics, build(:'lanalytics:root'))
        Stub.request(:learnanalytics, :get, '/metrics')
          .to_return Stub.json([
            {'name' => 'client_combination_usage', 'available' => true},
            {'name' => 'active_user_count', 'available' => true},
            {'name' => 'certificates', 'available' => true},
          ])
        Stub.request(
          :learnanalytics, :get, '/metrics/client_combination_usage',
          query: hash_including({})
        ).to_return Stub.json([])
        Stub.request(
          :learnanalytics, :get, '/metrics/active_user_count',
          query: hash_including({})
        ).to_return Stub.json({'active_users' => 0})
        Stub.request(:learnanalytics, :get, '/metrics/certificates')
          .to_return Stub.json({
            'record_of_achievement' => 0,
            'confirmation_of_participation' => 0,
          })
      end

      it 'renders age distribution and client usage tables' do
        action
        expect(response).to render_template :show
        expect(response.body).to include 'Age Distribution'
        expect(response.body).to include 'Client Usage'
      end

      it 'renders KPI score cards' do
        action
        expect(response.body).to include 'Enrollments'
        expect(response.body).to include 'Learners'
        expect(response.body).to include 'Activity'
        expect(response.body).to include 'Certificates'
      end
    end

    context 'without permissions' do
      it 'redirects to the homepage' do
        action
        expect(response).to redirect_to root_path
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the login page' do
      action
      expect(response).to redirect_to root_path
    end
  end
end
