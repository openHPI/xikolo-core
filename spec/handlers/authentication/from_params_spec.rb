# frozen_string_literal: true

require 'spec_helper'

describe Authentication, '.from_params' do
  subject(:result) { described_class.from_params(params) }

  let(:user) { create(:'account_service/user', password: 'secret123') }
  let(:params) { ActionController::Parameters.new(login_params).permit! }

  context 'with an email address and a password' do
    let(:login_params) { {email: user.primary_email.address, password: 'secret123'} }

    it 'authenticates the user' do
      expect(result).to be_authenticated
      expect(result.session.user_id).to eq user.id
    end
  end

  context 'with an authorization to create an account for' do
    let(:login_params) { {authorization: authorization.id, autocreate: '1'} }

    let(:authorization) do
      create(:'account_service/authorization',
        user: nil,
        provider: 'saml',
        info: {name: 'New User', email: 'new-user@example.com'})
    end

    it 'creates an account and authenticates' do
      expect(result).to be_authenticated
      expect(authorization.reload.user_id).to eq result.session.user_id
    end

    context 'when an account with the authorization email already exists' do
      let!(:user) { create(:'account_service/user') }

      before { user.primary_email.update!(address: 'new-user@example.com') }

      it 'links to the existing account without creating a new one' do
        expect { result }.not_to change(AccountService::User, :count)
        expect(result).to be_authenticated
        expect(result.session.user_id).to eq user.id
      end
    end
  end

  context 'with incomplete parameters' do
    let(:login_params) { {password: 'secret123'} }

    it 'raises' do
      expect { result }.to raise_error(Authentication::UnsupportedAuthMethod, /Unknown auth method/)
    end

    it 'does not report the password' do
      expect { result }.to raise_error(Authentication::UnsupportedAuthMethod) do |error|
        expect(error.message).not_to include 'secret123'
      end
    end
  end
end
