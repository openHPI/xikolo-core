# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard: Profile: Show', type: :request do
  subject(:request) { get '/dashboard/profile', headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:email) { 'jon.doe@internet.org' }
  let(:features) { {} }
  let(:user_resource) do
    attributes_for(:'account_service/user', id: user.id, email:)
      .merge(consents_url: "http://localhost:3000/account_service/users/#{user_id}/consents")
  end
  let(:user) { create(:'account_service/user', id: user_id) }

  before do
    stub_user_request(id: user_id, features:)

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user_resource)
    Stub.request(:account, :get, "/users/#{user_id}/emails")
      .to_return Stub.json([attributes_for(:'account_service/email', user_id:, address: email)])
    Stub.request(:account, :get, "/users/#{user_id}/profile")
      .to_return Stub.json({user_id:, fields: []})
    Stub.request(:account, :get, "/authorizations?user=#{user_id}")
      .to_return Stub.json({})
    Stub.request(:account, :get, "/users/#{user_id}/consents")
      .to_return Stub.json([])
  end

  context 'with the profile feature flipper' do
    let(:features) { {'profile' => 'true'} }

    it 'can be accessed' do
      request
      expect(response).to have_http_status :ok
    end
  end

  context 'without the profile feature flipper' do
    it 'cannot be accessed' do
      expect { request }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
