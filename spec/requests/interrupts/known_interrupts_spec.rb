# frozen_string_literal: true

require 'spec_helper'

describe 'Interrupts: Known interrupt types', type: :request do
  subject { request; response }

  let(:request) { get '/' }
  let(:interrupts) { [] }
  let(:features) { {} }
  let(:born_at) { nil }
  let(:user) { create(:'account_service/user', completed_profile: true, born_at:) }

  before do
    create(:'account_service/treatment') if interrupts.include?('new_consents')
    create(:'account_service/policy') if interrupts.include?('new_policy')
    sign_in(user:)
  end

  context 'with guardian_consent interrupt' do
    let(:interrupts) { ['guardian_consent'] }
    let(:born_at) { 12.years.ago }

    it { is_expected.to redirect_to '/account/guardian_consent' }
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
