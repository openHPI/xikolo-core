# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Dashboard: Show', type: :request do
  subject(:action) { get('/admin/dashboard') }

  context 'for logged-in users' do
    before { sign_in(user:) }

    context 'with permissions' do
      let(:user) { create(:'account_service/user') }

      before do
        role = create(:'account_service/role', permissions: ['global.dashboard.show'])
        create(:'account_service/grant', principal: user, role:)
      end

      it 'renders age distribution table' do
        action
        expect(response).to render_template :show
        expect(response.body).to include 'Age Distribution'
      end

      it 'renders KPI score cards' do
        action
        expect(response.body).to include 'Enrollments'
        expect(response.body).to include 'Learners'
        expect(response.body).to include 'Certificates'
      end
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

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
