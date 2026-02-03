# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Accounts: Create', type: :request do
  subject(:result) { post '/account', params: }

  before do
    Stub.request(:account, :get, '/policies')
      .to_return Stub.json(policies)
    Stub.request(:account, :get, '/treatments')
      .to_return Stub.json([])
    Stub.request(:account, :get, "/users/#{user_id}/emails")
      .to_return Stub.json([{id: SecureRandom.uuid}])
  end

  let!(:create_user_stub) do
    Stub.request(:account, :post, '/users')
      .to_return Stub.json build(:'account:user', id: user_id)
  end
  let(:params) { {user: user_params} }
  let(:user_id) { generate(:user_id) }
  let(:user_params) do
    {
      full_name: 'Jane Doe',
      email: 'doe@plattner.de',
      status: 'Teacher',
      password: 'secret',
      password_confirmation: 'secret',
      language: 'en',
      born_at: '1990-01-20',
    }
  end
  let(:policies) { [] }

  it 'responds with 404 Not Found when the native registration is disabled' do
    expect { result }.to raise_error AbstractController::ActionNotFound
  end

  context 'with native registration enabled' do
    let(:anonymous_session) do
      super().merge(features: {'account.registration' => true})
    end

    context 'with complete data' do
      it { is_expected.to redirect_to verify_account_path }

      it 'sends the user to xi-account' do
        result

        expect(
          create_user_stub.with(body: {
            full_name: 'Jane Doe',
            email: 'doe@plattner.de',
            status: 'Teacher',
            password: 'secret',
            password_confirmation: 'secret',
            language: 'en',
            born_at: '1990-01-20',
          })
        ).to have_been_requested
      end

      it 'triggers a welcome email to be sent out' do
        expect(Msgr).to receive(:publish).with(
          hash_including(
            # Absolute URL is required, as this will be inserted into the welcome mail
            confirmation_url: %r{^http://www.example.com/account/confirm/.+$}
          ),
          to: 'xikolo.web.account.sign_up'
        )

        result
      end

      context 'when there are policies to accept' do
        let(:policies) do
          [
            {version: 3},
            {version: 2},
          ]
        end
        let!(:accept_policy_stub) do
          Stub.request(:account, :patch, "/users/#{user_id}")
            .to_return Stub.response(status: 204)
        end

        it 'marks the latest version as accepted' do
          result

          expect(
            accept_policy_stub.with(body: {accepted_policy_version: 3})
          ).to have_been_requested
        end
      end

      context 'when there is something to consent to' do
        let(:params) { super().merge(treatments: 'user_data,marketing', consent: ['user_data']) }
        let!(:consent_stub) do
          Stub.request(:account, :patch, "/users/#{user_id}/consents")
            .to_return Stub.response(status: 204)
        end

        it 'submits the consents for all treatments to xi-account' do
          result

          expect(
            consent_stub.with(body: [{name: 'user_data', consented: true}, {name: 'marketing', consented: false}].to_json)
          ).to have_been_requested
        end
      end
    end

    context 'with incomplete data' do
      let(:user_params) do
        {
          full_name: 'Jane Doe',
        }
      end

      it 'renders the form again, including errors' do
        result
        expect(response.body).to include 'Create a new account'
        expect(response.body).to include 'We found some errors'
        expect(response.body).to include 'can&#39;t be blank'
      end
    end

    context 'with already known e-mail address' do
      let(:create_user_stub) do
        Stub.request(:account, :post, '/users')
          .to_return Stub.json({
            errors: {
              email: ['has already been taken'],
            },
          }, status: 422)
      end

      context 'when credentials match' do
        before do
          Stub.request(:account, :post, '/sessions')
            .with(body: hash_including(ident: 'doe@plattner.de', password: 'secret'))
            .to_return Stub.json({id: SecureRandom.uuid})
        end

        it 'interprets the request as login and sends the user to the dashboard' do
          expect(result).to redirect_to dashboard_path
        end
      end

      context 'when credentials do not match' do
        before do
          Stub.request(:account, :post, '/sessions')
            .with(body: hash_including(ident: 'doe@plattner.de', password: 'secret'))
            .to_return Stub.json({
              errors: {base: ['invalid credentials']},
            }, status: 422)
        end

        it 'renders the form again, including an explanatory error' do
          result
          expect(response.body).to include 'Create a new account'
          expect(response.body).to include 'We found some errors'
          expect(response.body).to include 'The e-mail address you entered has already been registered.'
        end
      end
    end
  end
end
