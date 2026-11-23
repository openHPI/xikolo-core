# frozen_string_literal: true

require 'spec_helper'

describe AccountService::Authorization, type: :model do
  subject(:authorization) { create(:'account_service/authorization', attributes) }

  let(:attributes) { {} }

  describe '#info' do
    subject { authorization.info }

    describe 'update' do
      subject { authorization.reload.info }

      before { authorization.update! info: {'key' => false} }

      it { is_expected.to eq 'key' => false }
    end
  end

  describe '#update' do
    subject(:update) { authorization.update! uid: 1234 }

    let(:user) { create(:'account_service/user') }
    let(:attributes) { {user:} }

    it 'does trigger a provider update' do
      expect(AccountService::Provider).to receive(:update).with(authorization)
      update
    end
  end

  describe '#destroy' do
    before { authorization }

    it 'does not trigger a provider update' do
      expect(AccountService::Provider).not_to receive(:update)
      authorization.destroy
    end
  end

  describe '.from_omniauth' do
    subject(:from_omniauth) { described_class.from_omniauth(payload) }

    let(:payload) do
      {
        provider: 'saml',
        uid: 'uid-1',
        credentials: {token: 'abc', secret: '123', expires_at: 1.day.from_now.to_i},
        info: {name: 'SSO User', email: 'sso-user@example.com'},
        extra: {},
      }
    end

    context 'with a new authorization' do
      it 'creates and persists the authorization' do
        expect { from_omniauth }.to change(described_class, :count).by(1)
        expect(from_omniauth).to be_persisted
      end

      it 'stores the credentials and info' do
        authorization = from_omniauth
        expect(authorization.provider).to eq 'saml'
        expect(authorization.uid).to eq 'uid-1'
        expect(authorization.token).to eq 'abc'
        expect(authorization.secret).to eq '123'
        expect(authorization.expires_at).to be_within(1.second).of 1.day.from_now
        expect(authorization.info[:email]).to eq 'sso-user@example.com'
      end
    end

    context 'with an existing authorization' do
      let!(:authorization) do
        create(:'account_service/authorization', provider: 'saml', uid: 'uid-1', token: 'old')
      end

      it 'updates the existing record instead of creating a new one' do
        expect { from_omniauth }.not_to change(described_class, :count)
        expect(from_omniauth.id).to eq authorization.id
        expect(from_omniauth.token).to eq 'abc'
      end
    end

    context 'without credentials in the payload' do
      before do
        create(:'account_service/authorization',
          provider: 'saml',
          uid: 'uid-1',
          token: 'stored-token',
          secret: 'stored-secret')
        payload[:credentials] = {}
      end

      it 'keeps the stored credentials' do
        expect(from_omniauth.token).to eq 'stored-token'
        expect(from_omniauth.secret).to eq 'stored-secret'
      end
    end

    context 'without info in the payload' do
      before { payload[:info] = {} }

      context 'with stored info on an existing authorization' do
        before do
          create(:'account_service/authorization',
            user: nil,
            provider: 'saml',
            uid: 'uid-1',
            info: {email: 'stored@example.com'})
        end

        it 'keeps the stored info' do
          expect(from_omniauth.info[:email]).to eq 'stored@example.com'
        end
      end

      context 'without any info' do
        context 'on an authorization that is already connected to a user' do
          before do
            create(:'account_service/authorization',
              user: create(:'account_service/user'),
              provider: 'saml',
              uid: 'uid-1',
              info: {})
          end

          it 'does not raise, as the provider cannot act without an e-mail address' do
            expect { from_omniauth }.not_to raise_error
          end
        end
      end
    end
  end

  describe 'an authorization per provider and uid' do
    it 'stores at most one authorization for a provider and uid' do
      create(:'account_service/authorization', provider: 'saml', uid: 'uid-1')

      expect { create(:'account_service/authorization', provider: 'saml', uid: 'uid-1') }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows the same uid for different providers' do
      create(:'account_service/authorization',
        provider: 'saml',
        uid: 'uid-1',
        info: {email: 'first@example.com'})
      create(:'account_service/authorization',
        provider: 'hpi_saml',
        uid: 'uid-1',
        info: {email: 'second@example.com'})

      expect(described_class.count).to be 2
    end
  end
end
