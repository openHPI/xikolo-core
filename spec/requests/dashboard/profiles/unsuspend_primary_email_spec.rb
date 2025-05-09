# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard: Profile: Unsuspend Primary Email', type: :request do
  subject(:request) { get '/dashboard/profile/unsuspend_primary_email', headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:email) { build(:'account:email', user_id:, address: 'jon.doe@internet.org', primary: true) }
  let(:features) { {} }
  let(:user_id) { generate(:user_id) }
  let(:user) { build(:'account:user', id: user_id, email: email['address']) }

  before do
    stub_user_request(id: user_id, features:)
  end

  context 'with the profile feature flipper' do
    let(:features) { {'profile' => 'true'} }
    let(:email_suspension_stub) do
      Stub.request(:account, :delete, "/users/#{user_id}/emails/#{email['id']}/suspension")
        .to_return Stub.json({msg: 'e-mail address unsuspended'}, status: 200)
    end

    before do
      Stub.request(:account, :get, "/users/#{user_id}").to_return Stub.json(user)
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
    it 'cannot be accessed' do
      expect { request }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
