# frozen_string_literal: true

require 'spec_helper'

describe Authentication::Credentials do
  subject(:result) { described_class.call(ident: email, password: attempted_password) }

  let(:user) { create(:'account_service/user', password: 'secret123') }
  let(:email) { user.primary_email.address }
  let(:attempted_password) { 'secret123' }

  context 'with valid credentials' do
    it 'authenticates and starts a session' do
      expect(result).to be_authenticated
      expect(result.session).to be_persisted
      expect(result.session.user_id).to eq user.id
    end
  end

  context 'with invalid credentials' do
    let(:attempted_password) { 'wrong' }

    it 'fails with :invalid_credentials' do
      expect(result).not_to be_authenticated
      expect(result.error_code).to eq :invalid_credentials
    end
  end

  context 'with an unconfirmed user' do
    before { user.primary_email.update!(confirmed: false, force: true) }

    it 'fails with :unconfirmed_user' do
      expect(result).not_to be_authenticated
      expect(result.error_code).to eq :unconfirmed_user
    end
  end

  context 'with an archived user' do
    before { user.update!(archived: true) }

    it 'fails with :archived_user' do
      expect(result).not_to be_authenticated
      expect(result.error_code).to eq :archived_user
    end
  end

  context 'with a banned user' do
    before { user.update!(banned_at: Time.current) }

    it 'fails with :banned_user' do
      expect(result).not_to be_authenticated
      expect(result.error_code).to eq :banned_user
    end
  end

  context 'with an invalid password digest' do
    before do
      allow(AccountService::User).to receive(:authenticate).and_raise(BCrypt::Errors::InvalidHash)
    end

    it 'fails with :invalid_digest' do
      expect(result).not_to be_authenticated
      expect(result.error_code).to eq :invalid_digest
    end
  end

  describe '.verify' do
    subject(:verified) { described_class.verify(ident: email, password: attempted_password) }

    context 'with valid credentials' do
      it { is_expected.to be true }

      it 'does not start a session' do
        expect { verified }.not_to change(AccountService::Session, :count)
      end
    end

    context 'with invalid credentials' do
      let(:attempted_password) { 'wrong' }

      it { is_expected.to be false }
    end

    context 'with a banned user' do
      before { user.update!(banned_at: Time.current) }

      it { is_expected.to be false }
    end

    context 'with an invalid password digest' do
      before do
        allow(AccountService::User).to receive(:authenticate).and_raise(BCrypt::Errors::InvalidHash)
      end

      it { is_expected.to be false }
    end
  end
end
