# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard: Profile: Unsuspend Primary Email', type: :request do
  subject(:request) { get '/dashboard/profile/unsuspend_primary_email' }

  let(:email_id) { generate(:uuid) }
  let(:email) do
    attributes_for(:'account_service/email', id: email_id, user_id:, address: email_address, primary: true)
      .merge(suspension_url: "http://localhost:3000/account_service/users/#{user_id}/emails/#{email_id}/suspension")
  end
  let(:user_id) { generate(:user_id) }
  let(:email_address) { 'jon.doe@internet.org' }
  let(:user) { create(:'account_service/user', id: user_id) }
  let(:authenticate) { true }

  before do
    sign_in(user:) if authenticate
    user.primary_email.update!(address: email_address)
  end

  context 'with the profile feature flipper' do
    let(:features) { {'profile' => 'true'} }
    let(:user_resource) do
      attributes_for(:'account_service/user', id: user_id, email: email_address)
        .merge(emails_url: "http://localhost:3000/account_service/users/#{user_id}/emails")
    end
    let(:email_suspension_stub) do
      Stub.request(:account, :delete, "/users/#{user_id}/emails/#{email_id}/suspension")
        .to_return Stub.json({msg: 'e-mail address unsuspended'}, status: 200)
    end

    before do
      Stub.request(:account, :get, "/users/#{user_id}").to_return Stub.json(user_resource)
      Stub.request(:account, :get, "/users/#{user_id}/emails")
        .to_return Stub.json([email])
      email_suspension_stub
    end

    it 'redirects to the profile' do
      request
      expect(response).to redirect_to profile_path
    end

    it 'deletes the email suspension' do
      request
      expect(email_suspension_stub).to have_been_requested
    end
  end

  context 'without the profile feature flipper' do
    before do
      AccountService::Feature.where(name: 'profile').delete_all
    end

    it 'cannot be accessed' do
      expect { request }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
