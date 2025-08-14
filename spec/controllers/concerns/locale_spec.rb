# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Locale, type: :controller do
  # Explicitly derive the anonymous test controller from AC::Base as
  # otherwise - depending on test order - other callbacks are already
  # registered and raised method stub errors.
  controller(ActionController::Base) do
    include Locale

    # Test action to invoke
    def index
      render status: :ok, plain: I18n.locale
    end

    # Concern dependencies not (yet) extracted into a concern
    #
    # Must defined as methods here to setup verfied stubs
    def current_user; end
  end

  let(:response) { get :index, params:, session: }

  let(:params) { {} }
  let(:session) { {} }
  let(:accept_language) { nil }
  let(:user_preferred_language) { nil }

  let(:current_user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'user' => {'anonymous' => true, 'preferred_language' => user_preferred_language}
    )
  end

  before do
    # This specs depend on some locales been available
    # Do sanity check here and abort if they are missing.
    expect(Xikolo.config.locales['available']).to include('en', 'de')

    # We also expect a few locales to *not* be available
    # to test for negative matches. These must be changed if the
    # locale becomes available.
    expect(Xikolo.config.locales['available']).not_to include('fi', 'fr', 'nl', 'es', 'uk', 'it')

    # Inject HTTP header for contention negotiation
    request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language

    # Setup stub for current user
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  describe '#set_locale' do
    subject(:locale) { response.body }

    it 'defaults to default locale' do
      expect(locale).to eq 'en'
    end

    # If no locale is detected the request must be configured
    # to use the default locale.
    context 'with default locale: de' do
      before do
        xi_config <<~YML
          locales:
            default: de
            available: [de, en]
        YML
      end

      it { is_expected.to eq 'de' }
    end

    # If a locale has been set, e.g. in the previous request
    # in the same worker process it must be reset to the default locale.
    context 'with previously set different locale' do
      it 'resets to the default locale' do
        I18n.with_locale(:de) do
          expect(locale).to eq 'en'
        end
      end
    end

    context 'with Accept-Language header' do
      context 'with available language: "de-DE,de,en-US,en"' do
        let(:accept_language) { 'de-DE,de,en-US,en' }

        it { is_expected.to eq 'de' }
      end

      context 'with prioritized language: "en;q=0.9,de"' do
        let(:accept_language) { 'en;q=0.9,de' }

        it { is_expected.to eq 'de' }
      end

      context 'with unavailable language: "fi,de,en"' do
        let(:accept_language) { 'fi,de,en' }

        it { is_expected.to eq 'de' }
      end
    end

    context 'with user preferred language' do
      let(:user_preferred_language) { 'de' }

      it { is_expected.to eq 'de' }

      context 'with unavailable language' do
        let(:user_preferred_language) { 'fi' }
        let(:accept_language) { 'de,en' }

        it 'falls back to HTTP accepted language' do
          expect(locale).to eq 'de'
        end
      end
    end

    context 'with session locale' do
      let(:session) { {locale: 'de'} }

      it { is_expected.to eq 'de' }

      context 'with unavailable locale' do
        let(:session) { {locale: 'fi'} }
        let(:user_preferred_language) { 'de' }

        it 'falls back user preference' do
          expect(locale).to eq 'de'
        end
      end
    end

    context 'with ?locale' do
      let(:params) { {locale: 'de'} }

      it { is_expected.to eq 'de' }

      it 'stores locale in session' do
        response
        expect(request.session.to_h).to include 'locale' => 'de'
      end

      context 'with overriden query parameter' do
        before do
          controller.class_eval do
            def locale_param
              params[:lang]
            end
          end
        end

        let(:params) { {locale: 'it', lang: 'de'} }

        it { is_expected.to eq 'de' }
      end

      context 'with signed in user' do
        let(:current_user) do
          Xikolo::Common::Auth::CurrentUser.from_session(
            'user_id' => 'USER_ID',
            'user' => {'anonymous' => false, 'preferred_language' => user_preferred_language}
          )
        end

        let!(:stub) do
          Stub.request(:account, :patch, '/users/USER_ID')
            .with(body: {'language' => 'de'})
        end

        it 'updates user preferred language' do
          response
          expect(stub).to have_been_requested
        end
      end

      context 'with unavailable language' do
        let(:params) { {locale: 'fi'} }
        let(:session) { {locale: 'de'} }

        it 'falls back to session language' do
          expect(locale).to eq 'de'
        end
      end
    end
  end
end
