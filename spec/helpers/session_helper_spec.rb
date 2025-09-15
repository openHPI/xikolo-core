# frozen_string_literal: true

require 'spec_helper'

describe SessionHelper, type: :helper do
  subject(:ctx) do
    Struct.new(:session, :current_user, :request) do
      include SessionHelper
    end.new(session, current_user, request)
  end

  let(:current_user) { nil }

  describe '#logout' do
    subject(:logout) { ctx.logout }

    let!(:delete_session_req) do
      Stub.request(:account, :delete, '/sessions/1')
        .and_return response
    end

    let(:response) { {status: 200} }
    let(:current_user) { instance_double(Xikolo::Common::Auth::CurrentUser::Authenticated) }

    before do
      allow(current_user).to receive(:session_id).and_return(1)
      allow(request).to receive(:env).and_return({})
    end

    it 'removes the session resource' do
      logout
      expect(delete_session_req).to have_been_requested
    end

    context 'with 404 Not Found' do
      let(:response) { {status: 404} }

      it 'does not raise any error' do
        expect { logout }.not_to raise_error
      end
    end

    context 'with 502 Bad Gateway' do
      let(:response) { {status: 502} }

      it 'does not raise any error' do
        expect { logout }.not_to raise_error
      end
    end

    context 'with 503 Service Unavailable' do
      let(:response) { {status: 503} }

      it 'does not raise any error' do
        expect { logout }.not_to raise_error
      end
    end

    context 'with 504 Gateway Timeout' do
      let(:response) { {status: 504} }

      it 'does not raise any error' do
        expect { logout }.not_to raise_error
      end
    end

    context 'with 500 Internal Server Error' do
      let(:response) { {status: 500} }

      it 'error is ignored but attached and reported' do
        expect(Mnemosyne).to receive(:attach_error) do |e|
          expect(e).to be_a Restify::InternalServerError
        end

        expect(Sentry).to receive(:capture_exception) do |e|
          expect(e).to be_a Restify::InternalServerError
        end

        expect { logout }.not_to raise_error
      end
    end
  end
end
