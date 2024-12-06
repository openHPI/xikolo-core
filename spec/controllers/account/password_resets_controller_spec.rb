# frozen_string_literal: true

require 'spec_helper'

describe Account::PasswordResetsController, type: :controller do
  let(:reset_response) do
    Stub.json({
      user_id: '7563b0ed-f64f-441b-bb05-a673eb3036af',
      id: 'abcd',
      self_url: 'http://localhost:3100/password_resets/abcd',
    })
  end

  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}',
      password_reset_url: '/password_resets/{id}',
      password_resets_url: '/password_resets'
    )
  end

  describe '#create' do
    subject(:action) { -> { post :create, params: } }

    let(:params) { {} }

    it 'responds with 404 Not Found when the native login is disabled' do
      expect { action.call }.to raise_error AbstractController::ActionNotFound
    end

    context 'with native login enabled' do
      let(:anonymous_session) do
        super().merge(features: {'account.login' => true})
      end

      context 'with email address' do
        let!(:req) do
          Stub.request(
            :account, :post, '/password_resets',
            body: hash_including(email: 'goethe@music.de')
          ).to_return reset_response
        end
        let(:params) { {reset: {email: 'goethe@music.de'}} }

        it 'requests backend' do
          action.call
          expect(req).to have_been_requested
        end
      end

      context 'with empty email address' do
        let!(:req) do
          Stub.request(
            :account, :post, '/password_resets',
            body: hash_including(email: 'goethe@music.de')
          )
        end
        let(:params) { {reset: {email: ''}} }

        it 'does not request backend' do
          action.call
          expect(req).not_to have_been_requested
        end

        it 'redirects to form again' do
          action.call
          expect(response).to render_template :new
        end
      end
    end
  end

  describe '#update' do
    subject(:action) { -> { patch :update, params: params.merge(id: 'abcd') } }

    let(:params) { {} }

    before do
      Stub.request(
        :account, :get, '/password_resets/abcd'
      ).to_return reset_response
    end

    it 'responds with 404 Not Found when the native login is disabled' do
      expect { action.call }.to raise_error AbstractController::ActionNotFound
    end

    context 'with native login enabled' do
      let(:anonymous_session) do
        super().merge(features: {'account.login' => true})
      end

      context 'with matching passwords' do
        let!(:req) do
          Stub.request(
            :account, :patch, '/password_resets/abcd',
            body: {password: 'secret'}
          ).to_return reset_response
        end
        let(:params) { {reset: {password: 'secret', password_confirmation: 'secret'}} }

        it 'calls backend' do
          action.call
          expect(req).to have_been_requested
        end

        context 'with invalid password reset' do
          let(:reset_response) { Stub.response(status: 404) }

          it 'responds with 404 Not Found' do
            action.call
            expect(response).to render_template :not_found
          end
        end
      end

      context 'with not matching passwords' do
        let!(:req) do
          Stub.request(
            :account, :put, '/password_resets/abcd',
            body: {user_id: '7563b0ed-f64f-441b-bb05-a673eb3036af', id: 'abcd',
                  password: 'secret', password_confirmation: 'other'}
          )
        end
        let(:params) { {reset: {password: 'secret', password_confirmation: 'other'}} }

        it 'calls backend' do
          action.call
          expect(req).not_to have_been_requested
        end

        it 'shows the form again' do
          action.call
          expect(response).to render_template :show
        end
      end
    end
  end
end
