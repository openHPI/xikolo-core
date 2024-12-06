# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Password Resets: Show', type: :request do
  subject(:resp) do
    get("/account/reset/#{token}", headers:)
    response
  end

  let(:token) { '123' }
  let(:page)  { Capybara::Node::Simple.new(resp.body) }

  let(:reset_response) { Stub.json({id: token}) }

  before do
    Stub.request(:account, :get, "/password_resets/#{token}")
      .to_return reset_response
  end

  it 'responds with 404 Not Found when the native login is disabled' do
    expect { resp }.to raise_error AbstractController::ActionNotFound
  end

  context 'with native login enabled' do
    let(:anonymous_session) do
      super().merge(features: {'account.login' => true})
    end

    it 'responds with 200 Ok' do
      expect(resp).to have_http_status :ok
    end

    it 'renders show template' do
      page.find('form[action*=reset]').tap do |form|
        expect(form['method']).to eq 'post'
        expect(form['action']).to eq account_reset_path(token)

        expect(form).to have_field 'reset[password]', type: 'password'
        expect(form).to have_field 'reset[password_confirmation]', type: 'password'
      end
    end

    context 'with missing password reset' do
      let(:reset_response) { {status: 404} }

      it 'responds with 404 Not Found' do
        expect(resp).to have_http_status :not_found
      end
    end

    context 'when the request has both an invalid format and an invalid token' do
      let(:token) { 'highLightTitle.png' }
      let(:reset_response) { {status: 404} }

      before do
        Stub.request(:account, :get, '/password_resets/highLightTitle')
          .to_return reset_response
      end

      it 'responds with 404 Not Found' do
        expect(resp).to have_http_status :not_found
      end

      it 'shows a pretty error page' do
        expect(page).to have_content 'Invalid password reset link'
      end
    end
  end
end
