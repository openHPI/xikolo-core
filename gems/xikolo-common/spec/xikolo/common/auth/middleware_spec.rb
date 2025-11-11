# frozen_string_literal: true

require 'xikolo/common/auth/middleware'

RSpec.describe Xikolo::Common::Auth::Middleware do
  let(:rack_app) { double('rack_app', call: true) }
  let(:middleware) { described_class.new rack_app }
  let(:env) { {} }

  describe '#call' do
    subject { middleware.call env }

    it 'passes on the request to the next middleware' do
      subject
      expect(rack_app).to have_received(:call).with env
    end

    context 'with the correct path' do
      let(:env) { super().merge('PATH_INFO' => '/') }

      before do
        allow(middleware).to receive(:current_user_promise).and_return 'our_current_user'
      end

      it 'passes a user object to the next service' do
        subject
        expect(rack_app).to have_received(:call).with include('current_user' => 'our_current_user')
      end
    end
  end

  describe '#current_user_promise' do
    subject { middleware.current_user_promise(env).value! }
    let(:env) { super().merge('PATH_INFO' => '/') }
    let(:session_id) { nil }
    let(:user_response) { {id: user_id, anonymous: true} }
    let(:request_session_id) { 'anonymous' }
    let(:request_context_id) { 'root' }
    let(:user_id) { '81e01000-3100-4444-a001-000000000001' }

    before do
      Stub.service(
        :account,
        session_url: 'http://web.xikolo.tld/account_service/sessions/{id}{?embed,context}'
      )
    end

    let!(:context_stub) do
      Stub.request(
        :account, :get, "/sessions/#{request_session_id}",
        query: {embed: 'user,permissions,features', context: request_context_id}
      ).to_return Stub.json({
        id: session_id,
        user: user_response,
      })
    end

    context 'without an authorization header' do
      it 'resolves with an anonymous user' do
        expect(subject.anonymous?).to eq true
      end
    end

    context 'without a user' do
      let(:user_response) { nil }

      it 'resolves with an anonymous user' do
        expect(subject.anonymous?).to eq true
      end
    end

    context 'with an authorization header' do
      let(:env) { super().merge('HTTP_AUTHORIZATION' => auth_header) }
      let(:user_response) { {id: user_id, anonymous: false} }

      context 'with valid token' do
        let(:token) { 'abcdef1234567890' }
        let(:auth_header) { "Token token=#{token}" }
        let(:request_session_id) { "token=#{token}" }

        it 'resolves with an authenticated user' do
          expect(subject.authenticated?).to eq true
        end
      end

      context 'with valid legacy token' do
        let(:token) { 'abcdef1234567890' }
        let(:auth_header) { "Legacy-Token token=#{token}" }
        let(:request_session_id) { "token=#{token}" }

        it 'resolves with an authenticated user' do
          expect(subject.authenticated?).to eq true
        end
      end

      context 'with valid session ID' do
        let(:session_id) { '81e01000-3100-4444-a004-000000000001' }
        let(:auth_header) { "Xikolo-Session session_id=#{session_id}" }
        let(:request_session_id) { session_id }

        it 'resolves with an authenticated user' do
          expect(subject.authenticated?).to eq true
        end
      end
    end

    context 'with xikolo_context' do
      let(:env) { super().merge('xikolo_context' => context) }
      let(:request_context_id) { '00000002-3100-4444-9999-000000000001' }

      context 'with context as uuid' do
        let(:context) { request_context_id }

        it 'calls the stub with the according context_id' do
          subject
          expect(context_stub).to have_been_requested
        end
      end

      context 'with context as promise' do
        let(:context_promise) { double('context_promise') }
        let(:context) { context_promise }

        before { allow(context_promise).to receive(:value!).and_return(request_context_id) }

        it 'calls the stub with the according context_id' do
          subject
          expect(context_stub).to have_been_requested
        end
      end
    end
  end
end
