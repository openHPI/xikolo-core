# frozen_string_literal: true

require 'spec_helper'

describe Authentication::OmniAuth do
  subject(:result) { described_class.call(payload, current_user:) }

  let(:current_user) { nil }
  let(:payload) do
    {
      provider: 'saml',
      uid: 'uid-1',
      credentials: {token: 'abc', secret: '123'},
      info: {name: 'SSO User', email: auth_email},
      extra: {},
    }
  end
  let(:auth_email) { 'sso-user@example.com' }

  context 'with an authorization already linked to a user' do
    let(:user) { create(:'account_service/user') }

    before do
      create(:'account_service/authorization', user:, provider: 'saml', uid: 'uid-1')
    end

    it 'authenticates the linked user' do
      expect(result).to be_authenticated
      expect(result.session.user_id).to eq user.id
    end

    it 'is not a new authorization' do
      expect(result.new_authorization?).to be false
    end
  end

  context 'with a new authorization for an unknown email' do
    it 'requires user creation' do
      expect(result).not_to be_authenticated
      expect(result).to be_user_creation_required
    end

    it 'does not create a user' do
      expect { result }.not_to change(AccountService::User, :count)
    end
  end

  context 'with a new authorization matching an existing email' do
    let(:user) { create(:'account_service/user') }
    let(:auth_email) { user.primary_email.address }

    it 'links the authorization and authenticates' do
      expect(result).to be_authenticated
      expect(result.session.user_id).to eq user.id
      expect(AccountService::Authorization.find_by(uid: 'uid-1').user_id).to eq user.id
    end

    it 'reports a new authorization' do
      expect(result.new_authorization?).to be true
    end
  end

  context 'with a new authorization matching the e-mail address of a banned account' do
    let(:user) { create(:'account_service/user', :banned) }
    let(:auth_email) { user.primary_email.address }

    it 'reports the blocked account' do
      expect(result).not_to be_authenticated
      expect(result.error_code).to be :banned_user
    end

    it 'still reports the new authorization, so the controller can connect it' do
      expect(result.new_authorization?).to be true
    end
  end

  context 'when the current user is logged in and the authorization is unlinked' do
    let(:current_user) { instance_double(CurrentUser::User, logged_in?: true) }

    it 'requires the controller to decide which account to connect to' do
      expect(result).not_to be_authenticated
      expect(result).to be_user_creation_required
      expect(result.new_authorization?).to be true
    end

    it 'does not link the authorization' do
      result
      expect(result.authorization.user_id).to be_nil
    end
  end

  context 'when the authorization is linked but its e-mail address now belongs to another account' do
    let(:user) { create(:'account_service/user') }

    let(:auth_email) { 'taken@example.com' }

    before do
      create(:'account_service/authorization', user:, provider: 'saml', uid: 'uid-1')
      create(:'account_service/user').tap do |other|
        other.primary_email.update!(address: auth_email)
      end
    end

    it 'fails without raising' do
      expect(result).not_to be_authenticated
      expect(result.error_code).to be :invalid_information
    end
  end
end
