# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: LTI Providers: Create', type: :request do
  subject(:create_lti_provider) { post '/admin/lti_providers', params: {lti_provider: params}, headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[lti.provider.manage] }
  let(:params) do
    {
      consumer_key: 'consumer',
      description: 'Hands-on programming',
      domain: 'https://www.example.com',
      name: 'A Provider',
      presentation_mode: 'window',
      privacy: 'anonymized',
      shared_secret: 'secret',
    }
  end

  before { stub_user_request permissions: }

  it 'creates a new LTI provider and redirects to the index view' do
    expect { create_lti_provider }.to change(Lti::Provider, :count).from(0).to(1)
    expect(response).to redirect_to admin_lti_providers_path
    expect(flash[:success].first).to eq 'The LTI provider has successfully been created.'
  end

  context 'with an invalid attribute' do
    let(:params) { super().merge name: ' ' }

    it 'displays an error message' do
      expect { create_lti_provider }.not_to change(Lti::Provider, :count)
      expect(create_lti_provider).to render_template(:new)
      expect(flash[:error].first).to include 'The LTI provider has not been created.'
    end
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'redirects to the homepage' do
      create_lti_provider
      expect(response).to redirect_to root_path
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      create_lti_provider
      expect(response).to redirect_to root_path
    end
  end
end
