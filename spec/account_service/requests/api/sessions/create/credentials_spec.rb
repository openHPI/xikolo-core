# frozen_string_literal: true

require 'spec_helper'

describe 'Sessions: Create with Credentials', type: :request do
  subject(:resource) { api.rel(:sessions).post(payload).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:user) { create(:'account_service/user', password: 'secret123') }

  let(:response) do
    resource.response
  rescue Restify::ClientError, Restify::ServerError => e
    e.response
  end

  describe 'POST /sessions' do
    let(:ident) { user.emails.primary.take!.address }
    let(:payload) do
      {ident:, password: 'secret123', user_agent: 'User-Agent'}
    end

    context 'with valid credentials' do
      it 'responds with 201 Created' do
        expect(resource).to respond_with :created
      end

      it 'creates new session record' do
        expect { resource }.to change(AccountService::Session, :count).from(0).to(1)

        AccountService::Session.find(resource['id']).tap do |record|
          expect(record.user_id).to eq user.id
          expect(record.user_agent).to eq payload[:user_agent]
        end
      end

      it 'returns new session resource' do
        expect(resource['user_id']).to eq user.id
      end
    end

    context 'with invalid credentials' do
      let(:payload) do
        {ident:, password: 'invalid', user_agent: 'User-Agent'}
      end

      it 'responds with 422 Unprocessable Entity' do
        expect(response).to respond_with :unprocessable_content
      end

      it 'does not create session record' do
        expect { response }.not_to change(AccountService::Session, :count)
      end

      describe 'response error body' do
        subject(:errors) { response.decoded_body['errors'] }

        it { is_expected.to include 'ident' => ['invalid_credentials'] }
      end
    end

    context 'with non-primary email address' do
      let!(:secondary_email) { user.emails.create! attributes_for :'account_service/email' }

      let(:payload) do
        {
          ident: secondary_email.address,
          password: 'invalid',
          user_agent: 'User-Agent',
        }
      end

      it 'responds with 422 Unprocessable Entity' do
        expect(response).to respond_with :unprocessable_content
      end

      it 'does not create session record' do
        expect { response }.not_to change(AccountService::Session, :count)
      end

      describe 'response error body' do
        subject(:errors) { response.decoded_body['errors'] }

        it { is_expected.to include 'ident' => ['invalid_credentials'] }
      end
    end

    context 'with corrupted password digest' do
      before do
        user.update! password_digest: 'abcdefgh'
      end

      it 'responds with 422 Unprocessable Entity' do
        expect(response).to respond_with :unprocessable_content
      end

      it 'does not create session record' do
        expect { response }.not_to change(AccountService::Session, :count)
      end

      describe 'response error body' do
        subject(:errors) { response.decoded_body['errors'] }

        it { is_expected.to include 'ident' => ['invalid_digest'] }
      end
    end

    context 'with unconfirmed user' do
      before do
        user.emails.each {|e| e.update! confirmed: false, force: true }
      end

      it 'responds with 422 Unprocessable Entity' do
        expect(response).to respond_with :unprocessable_content
      end

      it 'does not create session record' do
        expect { response }.not_to change(AccountService::Session, :count)
      end

      describe 'response error body' do
        subject(:errors) { response.decoded_body['errors'] }

        it { is_expected.to include 'ident' => ['unconfirmed_user'] }
      end
    end

    context 'with archived user' do
      before { user.update! archived: true }

      it 'responds with 422 Unprocessable Entity' do
        expect(response).to respond_with :unprocessable_content
      end

      it 'does not create session record' do
        expect { response }.not_to change(AccountService::Session, :count)
      end

      describe 'response error body' do
        subject(:errors) { response.decoded_body['errors'] }

        it { is_expected.to include 'ident' => ['archived_user'] }
      end
    end
  end
end
