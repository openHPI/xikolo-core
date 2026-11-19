# frozen_string_literal: true

require 'spec_helper'

describe 'Interrupts: Non-interruptible requests', type: :request do
  subject { request; response }

  let(:request) { get '/', params:, headers: }
  let(:params) { {} }
  let(:headers) { {} }
  let(:user) { create(:'account_service/user', completed_profile: true) }

  context 'with anonymous user' do
    it { is_expected.to have_http_status :ok }
  end

  context 'with logged-in user' do
    before do
      create(:'account_service/treatment')
      sign_in(user:)
    end

    context 'AJAX request' do
      let(:headers) { super().merge('X-Requested-With' => 'XMLHttpRequest') }

      it { is_expected.to have_http_status :ok }
    end
  end
end
