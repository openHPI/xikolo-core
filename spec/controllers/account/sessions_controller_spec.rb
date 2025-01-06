# frozen_string_literal: true

require 'spec_helper'

describe Account::SessionsController, type: :controller do
  let(:valid_email) { 'p3k@example.de' }
  let(:valid_password) { 'PASSmaster3000' }
  let(:valid_user_id) { SecureRandom.uuid }
  let(:valid_session_id) { SecureRandom.uuid }
  let(:valid_user_agent) { 'Chrome32/MacOS' }
  let(:connect_auth_id) { SecureRandom.uuid }

  before do
    Stub.service(
      :account,
      email_url: '/emails/{id}',
      policies_url: '/policies',
      session_url: '/sessions/{id}'
    )
    Stub.request(
      :account, :get, '/policies'
    ).to_return Stub.json([])
  end

  describe '#new' do
    subject(:action) { -> { get :new, params: } }

    let(:params) { {} }

    context 'without parameters' do
      it 'renders login form' do
        action.call
        expect(response).to render_template(:new)
      end
    end

    context 'with connect_auth_id and post request' do
      subject(:action) { -> { post :new, params: } }

      let(:params) { {connect_auth_id:} }

      it 'renders login form' do
        action.call
        expect(response).to render_template(:new)
      end

      it 'displays a message' do
        action.call
        expect(flash[:notice].first)
          .to match(/Please login to your existing (.*) account to connect it with your (.*) login./)
      end
    end

    context 'with authorization' do
      let(:params) { {authorization: auth_id} }
      let(:auth_id) { SecureRandom.uuid }

      before do
        Stub.request(
          :account, :get, "/authorizations/#{auth_id}"
        ).to_return Stub.json({id: auth_id})
      end

      it 'renders login form' do
        action.call
        expect(response).to render_template(:auth_connect)
      end
    end

    context 'when logged in' do
      before { stub_user id: '3c0e0dac-deb5-4b36-a060-ae02f15cfed1' }

      it 'redirects to dashboard' do
        action.call
        expect(response).to redirect_to dashboard_url
      end

      context 'with redirect_url' do
        let(:params) { {**super(), redirect_url: '/oauth/authorize'} }

        it 'redirects to URL' do
          action.call
          expect(response).to redirect_to '/oauth/authorize'
        end
      end
    end
  end

  describe '#create' do
    subject(:action) { -> { post :create, params: } }

    let(:params) { {} }

    context 'with native login enabled' do
      let(:anonymous_session) do
        super().merge(features: {'account.login' => true})
      end

      context 'with valid credentials' do
        let!(:session_req) do
          Stub.request(
            :account, :post, '/sessions',
            body: hash_including(ident: valid_email, password: valid_password)
          ).to_return Stub.json({
            id: valid_session_id,
            user_id: valid_user_id,
            user_agent: valid_user_agent,
          })
        end
        let(:params) { {login: {email: valid_email, password: valid_password}} }

        it 'requests backend' do
          action.call
          expect(session_req).to have_been_requested
        end

        it 'redirects to dashboard' do
          action.call
          expect(response).to redirect_to dashboard_path
        end

        context 'with connect_auth_id' do
          let!(:auth_req) do
            Stub.request(
              :account, :get, "/authorizations/#{connect_auth_id}"
            ).to_return Stub.json({id: connect_auth_id})
          end
          let!(:auth_update_req) do
            Stub.request(
              :account, :put, "/authorizations/#{connect_auth_id}",
              body: hash_including(user_id: valid_user_id)
            ).to_return Stub.json({id: connect_auth_id})
          end
          let(:params) { {login: {email: valid_email, password: valid_password, connect_auth_id:}} }

          it 'requests backend' do
            action.call
            expect(session_req).to have_been_requested
            expect(auth_req).to have_been_requested
            expect(auth_update_req).to have_been_requested
          end

          it 'redirects to dashboard' do
            action.call
            expect(response).to redirect_to dashboard_path
          end

          it 'displays a success message' do
            action.call
            expect(flash[:success].first).to match(/You can login to (.*) using your (.*) account from now./)
          end

          context 'with old account existing' do
            let!(:auth_req) do
              Stub.request(
                :account, :get, "/authorizations/#{connect_auth_id}"
              ).to_return Stub.json({id: connect_auth_id, info: {email: old_email}, provider: 'saml'})
            end
            let(:update_answer) do
              {
                body: {
                  id: connect_auth_id,
                  errors: {provider: ['email_already_used_for_another_account']},
                }.to_json,
                status: 422,
                headers: {'Content-Type' => 'application/json'},
              }
            end
            let!(:auth_update_req) do
              Stub.request(
                :account, :put, "/authorizations/#{connect_auth_id}",
                body: hash_including(user_id: valid_user_id)
              ).to_return(update_answer)
            end
            let(:old_email) { 'p3k@example.com' }

            it 'requests backend' do
              action.call
              expect(session_req).to have_been_requested
              expect(auth_req).to have_been_requested
              expect(auth_update_req).to have_been_requested
            end

            it 'redirects to dashboard' do
              action.call
              expect(response).to redirect_to dashboard_path
            end

            it 'displays an error message' do
              action.call
              expect(flash[:error]).to include I18n.t(:'flash.error.enterprise_login_already_assigned',
                site_name: Xikolo.config.site_name)
            end
          end
        end

        context 'with redirect_url' do
          let(:login) { {email: valid_email, password: valid_password, redirect_url: profile_path} }
          let(:params) { {login:} }

          it 'redirects to profile' do
            action.call
            expect(session_req).to have_been_requested
            expect(response).to redirect_to profile_path
          end

          context 'with invalid redirect URL' do
            let(:login) do
              super().merge redirect_url: 'abch::45eeff383//334^^#abc'
            end

            it 'redirects to dashboard' do
              action.call
              expect(response).to redirect_to dashboard_path
            end
          end

          context 'with external redirect URL (1)' do
            let(:login) do
              super().merge redirect_url: 'https://google.com/img?q=abc#anchor'
            end

            it 'redirects to dashboard' do
              action.call
              expect(response).to redirect_to dashboard_path
            end
          end

          context 'with external redirect URL (2)' do
            let(:login) do
              super().merge redirect_url: 'https://test.host:80/dashboard/profile'
            end

            it 'redirects to profile' do
              action.call
              expect(response).to redirect_to profile_path
            end
          end
        end
      end

      context 'with invalid credentials' do
        let!(:session_req) do
          Stub.request(
            :account, :post, '/sessions',
            body: hash_including(ident: 'no_user@example.de', password: valid_password)
          ).to_return Stub.json(
            {errors: {ident: ['invalid_credentials']}},
            status: 422
          )
        end
        let(:params) { {login: {email: 'no_user@example.de', password: valid_password}} }

        it 'requests backend' do
          action.call
          expect(session_req).to have_been_requested
        end

        it 'displays an error message' do
          action.call
          expect(flash[:error].first).to eq I18n.t(:'flash.error.invalid_credentials')
        end

        it 'redirects to login page' do
          action.call
          expect(response).to redirect_to 'http://test.host/sessions/new'
        end

        context 'with redirect_url' do
          let(:params) { {login: {email: 'no_user@example.de', password: valid_password, redirect_url: profile_path}} }

          it 'stores the dashboard location as redirect target' do
            action.call
            jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
            expect(jar.signed['stored_location']).to eq '/dashboard/profile'
          end

          it 'redirects to profile' do
            action.call
            expect(response).to redirect_to 'http://test.host/sessions/new'
          end

          it 'requests backend' do
            action.call
            expect(session_req).to have_been_requested
          end

          it 'displays an error message' do
            action.call
            expect(flash[:error].first).to eq I18n.t(:'flash.error.invalid_credentials')
          end
        end

        context '(external login enabled)' do
          before do
            xi_config <<~YML
              portal_mode:
                external_login:
                  enabled: true
                  url: https://customer.example.com/login
            YML
          end

          it 'redirects to the external login page' do
            action.call
            expect(response).to redirect_to 'https://customer.example.com/login'
          end
        end
      end

      context 'with service error' do
        let!(:session_req) do
          Stub.request(
            :account, :post, '/sessions',
            body: hash_including(ident: 'user@example.de', password: valid_password)
          ).to_return Stub.json(
            {errors: {ident: ['invalid_digest']}},
            status: 422
          )
        end
        let(:params) { {login: {email: 'user@example.de', password: valid_password}} }

        it 'requests account service' do
          action.call
          expect(session_req).to have_been_requested
        end

        it 'displays an error message' do
          action.call
          expect(flash[:error].first).to eq I18n.t(:'flash.error.invalid_digest', url: new_account_reset_path)
        end

        it 'redirects to login page' do
          action.call
          expect(response).to redirect_to 'http://test.host/sessions/new'
        end
      end

      context 'with unconfirmed user rejection' do
        let!(:session_request) do
          Stub.request(:account, :post, '/sessions', body: {
            id: nil,
              ident: 'user@example.de',
              user_id: nil,
              password: valid_password,
              user_agent: nil,
          }).and_return Stub.json({
            errors: {ident: ['unconfirmed_user']},
          }, status: 422)
        end
        let(:params) do
          {
            login: {
              email: 'user@example.de',
              password: valid_password,
            },
          }
        end
        let(:user_id) { 'c7859058-d443-4fd3-871f-108d85c3d9ce' }
        let(:email_id) { 'e89d7bb2-4658-4a88-836d-fc459d65d34b' }

        before do
          Stub.request(:account, :get, '/emails/user@example.de')
            .to_return Stub.json({
              id: email_id,
              user_id:,
            })
        end

        it 'requests account service' do
          action.call
          expect(session_request).to have_been_requested
        end

        it 'displays an error message' do
          action.call
          flash[:error].first.tap do |msg|
            expect(msg).to include 'This e-mail address has not been confirmed yet.'
            expect(msg).to include 'Please check your inbox for an e-mail received after the registration process.'

            # Includes link to request new confirmation email
            # The `request` query parameter is a time-dependent signed blob
            expect(msg).to match %r{href='/account/confirm/new\?request=[\w%-]*'}
          end
        end

        it 'redirects to login page' do
          action.call
          expect(response).to redirect_to 'http://test.host/sessions/new'
        end
      end

      context 'with incomplete parameters' do
        let(:params) do
          {
            login: {
              password: valid_password,
            },
          }
        end

        it 'displays an error message' do
          action.call

          expect(flash[:error].first).to eq 'Something broke while we tried to log you in. Please try again later or contact the helpdesk.'
        end
      end
    end

    context 'with native login disabled' do
      let(:params) { {login: {email: valid_email, password: valid_password}} }

      it 'responds with 404 Not Found' do
        expect { action.call }.to raise_error AbstractController::ActionNotFound
      end

      context 'but attempting to connect accounts' do
        let(:params) do
          {
            login: {
              email: valid_email,
              password: valid_password,
              connect_auth_id: authorization.id,
            },
          }
        end
        let(:authorization) { create(:authorization, user: nil, provider: 'saml') }
        let!(:session_request) do
          Stub.request(:account, :post, '/sessions', body: {
            id: nil,
            ident: valid_email,
            user_id: nil,
            password: valid_password,
            user_agent: nil,
          }).and_return Stub.json({
            user_id: valid_user_id,
          })
        end
        let!(:auth_req) do
          Stub.request(
            :account, :get, "/authorizations/#{authorization.id}"
          ).to_return Stub.json({id: authorization.id})
        end
        let!(:auth_update_req) do
          Stub.request(
            :account, :put, "/authorizations/#{authorization.id}",
            body: hash_including(user_id: valid_user_id)
          ).to_return Stub.json({id: authorization.id})
        end

        it 'requests the account service to connect accounts' do
          action.call
          expect(session_request).to have_been_requested
          expect(auth_req).to have_been_requested
          expect(auth_update_req).to have_been_requested
        end
      end
    end
  end

  describe '#destroy' do
    subject(:action) { -> { delete :destroy, params: {id: session_id} } }

    before { stub_user }

    let(:session_id) { session[:id] }
    let!(:destroy_session_stub) do
      Stub.request(
        :account, :delete, "/sessions/#{session_id}"
      ).to_return Stub.json({})
    end

    it 'redirects the user' do
      action.call
      expect(response).to redirect_to root_url
    end

    it 'displays a message' do
      action.call
      expect(flash[:notice].first).to eq I18n.t(:'flash.success.logged_out')
    end

    it 'destroys the session' do
      action.call
      expect(destroy_session_stub).to have_been_requested
    end

    context 'when the user is logged in via SAML' do
      before do
        session.merge!(saml_provider: 'test_saml', saml_uid: 'A987654321', saml_session_index: 'A456789')
      end

      it 'clears the SAML session' do
        expect(session).to receive(:clear).twice.and_call_original
        action.call
      end
    end
  end

  describe '#authorization_callback' do
    subject(:action) { -> { get :authorization_callback, params: } }

    let(:params) { {provider: 'saml'} }
    let(:auth) do
      {
        provider: 'saml',
        uid: 'A12345',
        credentials: {
          token: 'abc',
          secret: '123',
        },
        info: {},
        extra: {},
      }
    end

    before do
      request.env['omniauth.auth'] = auth

      Stub.request(:account, :post, '/authorizations')
        .to_return authorization_response
    end

    context 'with authorization' do
      let(:authorization_response) { Stub.json({id: connect_auth_id, user_id: 2}) }
      let!(:session_req) do
        Stub.request(:account, :post, '/sessions')
          .to_return Stub.json({id: 1001, user_id: 2})
      end

      it 'redirects to dashboard' do
        expect(action.call).to redirect_to dashboard_path
      end

      context 'with new authorization' do
        let(:authorization_response) do
          {
            body: {
              id: connect_auth_id,
              user_id: nil,
            }.to_json,
            status: 201,
            headers: {'Content-Type' => 'application/json'},
          }
        end

        it 'redirects to dashboard' do
          expect(action.call).to redirect_to dashboard_path
        end

        it 'requests backend' do
          action.call
          expect(session_req).to have_been_requested
        end

        it 'displays a success message' do
          action.call
          expect(flash[:success].first).to match(/You can login to (.*) using your (.*) account from now./)
        end

        context 'with being logged in and old account existing' do
          let(:old_email) { 'p3k@example.com' }
          let(:update_answer) do
            {
              body: {
                id: connect_auth_id,
                errors: {provider: ['email_already_used_for_another_account']},
              }.to_json,
              status: 422,
              headers: {'Content-Type' => 'application/json'},
            }
          end
          let!(:auth_update_req) do
            Stub.request(
              :account, :put, "/authorizations/#{connect_auth_id}",
              body: hash_including(user_id: valid_user_id)
            ).to_return(update_answer)
          end

          before do
            stub_user id: valid_user_id, email: valid_email
            Stub.request(:account, :post, '/sessions')
              .to_return Stub.json({authorization_id: 1})
          end

          it 'requests backend' do
            action.call
            expect(session_req).to have_been_requested
            expect(auth_update_req).to have_been_requested
          end

          it 'redirects to dashboard' do
            action.call
            expect(response).to redirect_to dashboard_path
          end

          it 'displays an error message' do
            action.call
            expect(flash[:error]).to include I18n.t(:'flash.error.enterprise_login_already_assigned',
              site_name: Xikolo.config.site_name)
          end
        end
      end

      context 'with redirect cookie' do
        before do
          cookies.signed['stored_location'] = '/abc'
        end

        it 'redirects to stored location' do
          action.call
          expect(response).to redirect_to('/abc')
        end

        context 'with new authorization' do
          let(:authorization_response) { Stub.json({id: 1, user_id: 2}, status: :created) }

          it 'redirects to stored location' do
            action.call
            expect(response).to redirect_to('/abc')
          end
        end
      end
    end

    context 'without authorization' do
      let(:user_id) { '3c0e0dac-deb5-4b36-a060-ae02f15cfed1' }
      let(:authorization_response) { Stub.json({id: 1}) }
      let!(:session_req) do
        Stub.request(:account, :post, '/sessions').to_return Stub.json({id: 1001})
      end
      let!(:auth_update_req) do
        Stub.request(
          :account, :put, '/authorizations/1',
          body: hash_including(user_id:)
        ).to_return Stub.json({id: 1})
      end

      it 'redirects to login page' do
        action.call
        expect(response).to redirect_to 'http://test.host/sessions/new'
      end

      context 'with being logged in' do
        before do
          stub_user id: user_id, email: valid_email
        end

        it 'redirects to profile' do
          action.call
          expect(response).to redirect_to profile_path
        end

        it 'displays a success message' do
          action.call
          expect(flash[:success].first).to match(/You can login to (.*) using your (.*) account from now./)
        end

        it 'requests backend' do
          action.call
          expect(session_req).to have_been_requested
          expect(auth_update_req).to have_been_requested
        end

        context 'with redirect cookie' do
          before do
            cookies.signed['stored_location'] = '/abc'
          end

          it 'redirects to stored location' do
            action.call
            expect(response).to redirect_to('/abc')
          end
        end
      end
    end
  end
end
