# frozen_string_literal: true

require 'spec_helper'

describe 'Sessions: Create with User ID', type: :request do
  subject(:resource) { api.rel(:sessions).post(payload).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:user) { create(:'account_service/user') }

  let(:response) do
    resource.response
  rescue Restify::ClientError, Restify::ServerError => e
    e.response
  end

  describe 'POST /sessions with HPI provider' do
    let(:payload) { {authorization: authorization.id} }

    let(:authorization) do
      create(:'account_service/authorization', user: nil, provider:, info:, uid:)
    end

    let(:email) { attributes_for(:'account_service/email')[:address] }

    let(:uid) { '1' }
    let(:provider) { 'hpi' }
    let(:info) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email:,
        status: 'other',
      }
    end

    let(:full_name) { 'John Doe' }

    it_behaves_like 'an authorization provider'
  end

  describe 'POST /sessions with Mein Bildungsraum provider' do
    let(:payload) { {authorization: authorization.id} }

    let(:authorization) do
      create(:'account_service/authorization', user: nil, provider:, info:, uid:)
    end

    let(:email) { attributes_for(:'account_service/email')[:address] }

    let(:uid) { '1' }
    let(:provider) { 'mein_bildungsraum' }
    let(:info) { {} }

    context 'with a new authorization' do
      it 'responds with 422 Unprocessable Entity' do
        expect(response).to respond_with :unprocessable_content
      end

      it 'does not create a user record' do
        expect { response }.not_to change(AccountService::User, :count)
      end

      it 'does not create a session record do' do
        expect { response }.not_to change(AccountService::Session, :count)
      end

      it 'does not change the authorizations user' do
        expect { response }.not_to(change { authorization.reload.user_id })
      end

      describe 'payload error messages' do
        subject(:errors) { response.decoded_body['errors'] }

        it { is_expected.to include 'authorization' => ['user_creation_required'] }
      end

      context 'with autocreate parameter' do
        let(:payload) { {**super(), autocreate: true} }
        let(:full_name) { 'Mein Bildungsraum User' }

        # As the user is not yet confirmed and will be redirected to confirm that we can get their personal information
        it 'responds with 422 Unprocessable Entity' do
          expect(response).to respond_with :unprocessable_content
        end

        it 'returns that the user is unconfirmed' do
          expect(response.body).to include 'unconfirmed_user'
        end

        it 'creates a user record' do
          expect { response }.to change(AccountService::User, :count).from(0).to(1)
        end

        it 'does not create a session record' do
          expect { response }.not_to change(AccountService::Session, :count).from(0)
        end

        it 'assigns the authorization to the user' do
          expect { response }.to change { authorization.reload.user_id }.from(nil)
        end

        describe 'created user record' do
          subject(:user) { authorization.reload.user }

          before { response }

          it 'runs profile completion check' do
            expect(user.features.pluck(:name)).to \
              eq %w[account.profile.mandatory_completed]
          end

          describe '#email' do
            subject(:email) { user.email }

            it 'has a generated email address' do
              expect(email).to eq "#{uid}@example.com"
            end
          end

          describe '#full_name' do
            subject { user.full_name }

            it { is_expected.to eq full_name }
          end
        end
      end
    end
  end

  describe 'POST /sessions with HPI SAML provider' do
    let(:payload) { {authorization: authorization.id} }

    let(:authorization) do
      create(:'account_service/authorization', user: nil, provider:, info:, uid:)
    end

    let(:email) { attributes_for(:'account_service/email')[:address] }

    let(:uid) { '1' }
    let(:provider) { 'hpi_saml' }
    let(:info) do
      {
        name: 'John Doe',
        email:,
      }
    end

    let(:full_name) { 'John Doe' }

    it_behaves_like 'an authorization provider'
  end
end
