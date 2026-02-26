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
