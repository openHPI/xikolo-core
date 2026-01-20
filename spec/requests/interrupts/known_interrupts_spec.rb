# frozen_string_literal: true

require 'spec_helper'

describe 'Interrupts: Known interrupt types', type: :request do
  subject { request; response }

  let(:request) do
    get '/', headers: {
      'Authorization' => "Xikolo-Session session_id=#{stub_session_id}",
    }
  end
  let(:interrupts) { [] }
  let(:features) { {} }

  before do
    stub_user_request(
      id: '2611b7f0-b0dc-43d3-96be-81d810ba2535',
      features:,
      interrupts:
    )
  end

  context 'with new_consents interrupt' do
    let(:interrupts) { ['new_consents'] }

    it { is_expected.to redirect_to '/treatments' }
  end

  context 'with new_policy interrupt' do
    let(:interrupts) { ['new_policy'] }

    it { is_expected.to redirect_to '/account/policies' }
  end

  context 'with unsupported interrupt' do
    let(:interrupts) { ['2fa_upgrade'] }

    it { is_expected.to have_http_status :ok }
  end
end
