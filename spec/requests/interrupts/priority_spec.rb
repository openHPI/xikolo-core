# frozen_string_literal: true

require 'spec_helper'

describe 'Interrupts: Priority of multiple interrupts', type: :request do
  subject(:request) do
    get '/'
  end

  let(:born_at) { nil }
  let(:user) { create(:'account_service/user', completed_profile: true, born_at:) }
  let(:interrupts) { [] }

  before do
    create(:'account_service/treatment') if interrupts.include?('new_consents')
    create(:'account_service/policy') if interrupts.include?('new_policy')
    sign_in(user:)
  end

  context 'in order of priority' do
    let(:interrupts) { %w[new_consents new_policy] }

    it 'redirects to the most important interrupt (new consent required)' do
      request
      expect(response).to redirect_to '/treatments'
    end
  end

  context 'in different order' do
    let(:interrupts) { %w[new_policy new_consents] }

    it 'still redirects to the most important interrupt (new consent required)' do
      request
      expect(response).to redirect_to '/treatments'
    end
  end

  context 'with a missing guardian consent' do
    let(:interrupts) { %w[new_consents new_policy guardian_consent] }
    let(:born_at) { 12.years.ago }

    it 'redirects to the guardian consent, which takes precedence over all others' do
      request
      expect(response).to redirect_to '/account/guardian_consent'
    end
  end
end
