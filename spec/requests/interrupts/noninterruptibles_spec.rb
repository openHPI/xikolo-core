# frozen_string_literal: true

require 'spec_helper'

describe 'Interrupts: Non-interruptible requests', type: :request do
  subject { request; response }

  let(:request) { get '/', params:, headers: }
  let(:params) { {} }
  let(:headers) { {} }

  context 'with anonymous user' do
    let(:anonymous_session) do
      super().merge(interrupts: ['new_consents'])
    end

    it { is_expected.to have_http_status :ok }
  end

  context 'with logged-in user' do
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

    before do
      stub_user_request \
        id: '2611b7f0-b0dc-43d3-96be-81d810ba2535',
        interrupts: ['new_consents']
    end

    context 'request coming from mobile apps' do
      let(:params) { super().merge(in_app: 'true') }

      it { is_expected.to have_http_status :ok }
    end

    context 'AJAX request' do
      let(:headers) { super().merge('X-Requested-With' => 'XMLHttpRequest') }

      it { is_expected.to have_http_status :ok }
    end
  end
end
