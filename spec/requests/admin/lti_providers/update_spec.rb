# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: LTI Providers: Update', type: :request do
  subject(:update_lti_provider) { patch "/admin/lti_providers/#{provider.id}", params: {lti_provider: params}, headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:provider) { create(:lti_provider, :global) }
  let(:permissions) { %w[lti.provider.manage] }
  let(:params) do
    {
      name: 'An Updated Provider',
    }
  end

  before { stub_user_request permissions: }

  it 'updates the LTI provider' do
    expect { update_lti_provider }.to change { provider.reload.name }.from('Provider').to('An Updated Provider')
    expect(response).to redirect_to admin_lti_providers_path
    expect(flash[:success].first).to eq 'The LTI provider has successfully been saved.'
  end

  context 'with an invalid attribute' do
    let(:params) { {name: ' '} }

    it 'does not update the LTI provider' do
      expect { update_lti_provider }.not_to change { provider.reload.name }
      expect(update_lti_provider).to render_template(:edit)
      expect(flash[:error].first).to include 'The LTI provider has not been saved.'
    end
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'redirects to the homepage' do
      update_lti_provider

      expect(response).to redirect_to root_path
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      update_lti_provider

      expect(response).to redirect_to root_path
    end
  end
end
