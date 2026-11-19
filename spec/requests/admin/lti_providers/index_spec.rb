# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: LtiProviders: Index', type: :request do
  subject(:action) { get('/admin/lti_providers'); response }

  let(:user) { create(:'account_service/user', :admin) }

  context 'for logged-in users' do
    before { sign_in(user:) }

    it 'renders the index page' do
      action
      expect(response).to render_template :index
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

      it 'redirects to homepage' do
        action
        expect(response).to redirect_to root_path
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to homepage' do
      action
      expect(response).to redirect_to root_path
    end
  end
end
