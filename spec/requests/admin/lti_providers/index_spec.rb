# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: LtiProviders: Index', type: :request do
  subject(:action) { get('/admin/lti_providers', headers:); response }

  let(:headers) { {} }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['lti.provider.manage'] }

      it 'renders the index page' do
        action
        expect(response).to render_template :index
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

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
