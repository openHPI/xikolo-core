# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: LTI Providers: Destroy', type: :request do
  subject(:destroy_lti_provider) { delete "/admin/lti_providers/#{provider.id}" }

  let!(:provider) { create(:lti_provider, :global) }
  let(:user) { create(:'account_service/user', :admin) }
  let(:authenticate) { true }

  before { sign_in(user:) if authenticate }

  it 'deletes the LTI provider' do
    expect { destroy_lti_provider }.to change(Lti::Provider, :count).from(1).to(0)
    expect(response).to redirect_to admin_lti_providers_path
    expect(flash[:success].first).to eq 'The LTI provider has successfully been deleted.'
  end

  context 'without permissions' do
    let(:user) { create(:'account_service/user') }

    it 'redirects to the homepage' do
      destroy_lti_provider
      expect(response).to redirect_to root_path
    end
  end

  context 'for anonymous users' do
    let(:authenticate) { false }

    it 'redirects to the login page' do
      destroy_lti_provider
      expect(response).to redirect_to root_path
    end
  end
end
