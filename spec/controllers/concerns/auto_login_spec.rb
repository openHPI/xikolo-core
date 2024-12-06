# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoLogin, type: :controller do
  # Explicitly derive the anonymous test controller from AC::Base as
  # otherwise - depending on test order - other callbacks are already
  # registered and raised method stub errors.
  controller(ActionController::Base) do
    include AutoLogin

    # Test action to invoke
    def index
      render status: :ok, plain: 'INDEX'
    end

    # Concern dependencies not (yet) extracted into a concern
    #
    # Must defined as methods here to setup verfied stubs
    def current_user; end

    def store_location(*); end
  end

  let(:current_user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'user' => {'anonymous' => true}
    )
  end

  before do
    xi_config <<~YML
      auto_login:
        enabled: true
        issuer_domain:
          - example.org
          - example.com
        auth_provider: test
    YML

    # Currently AutoLogin has a few method dependencies not extracted
    # into concerns
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:store_location)
  end

  describe '#auto_login' do
    subject(:response) { get :index }

    context 'without SSL issuer' do
      it 'does not redirect' do
        expect(response).to have_http_status :ok
        expect(response.body).to eq 'INDEX'
      end
    end

    context 'with valid SSL issuer' do
      let(:redirect_target) { CGI.escape OmniAuth::Strategies::XikoloSAML.sign('/anonymous') }

      before { request.env['HTTP_X_SSL_ISSUER'] = 'john@example.org' }

      it { is_expected.to redirect_to "/auth/test?redirect_path=#{redirect_target}" }
    end

    context 'with invalid SSL issuer' do
      before { request.env['HTTP_X_SSL_ISSUER'] = 'john@example.de' }

      it 'does not redirect' do
        expect(response).to have_http_status :ok
        expect(response.body).to eq 'INDEX'
      end
    end
  end

  describe '#skip_auto_login!' do
    subject(:response) { get :index }

    before do
      controller.class_eval do
        skip_auto_login!
      end
    end

    it 'does not redirect' do
      request.env['HTTP_X_SSL_ISSUER'] = 'john@example.org'

      expect(response).to have_http_status :ok
      expect(response.body).to eq 'INDEX'
    end
  end
end
