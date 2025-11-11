# frozen_string_literal: true

require 'spec_helper'

describe AccountService::User, '#affiliation', type: :model do
  subject(:affiliation) { user.affiliation }

  let(:user) { create(:'account_service/user') }

  before do
    create(:'account_service/feature', owner: user, context: AccountService::Context.root, name: 'integration.external_booking')

    xi_config <<~YML
      external_booking:
        affiliation_field: affiliation
    YML
  end

  context 'without affiliation profile field' do
    it { expect { affiliation }.to raise_error(RuntimeError, 'User affiliation field affiliation required for JWT not found.') }
  end

  context 'with affiliation profile field' do
    let(:user) { create(:'account_service/user', :with_affiliation) }

    context 'without affiliation' do
      it { is_expected.to be_nil }
    end

    context 'with affiliation' do
      let(:user) { create(:'account_service/user', :with_affiliation, affiliation: 'ACME Inc.') }

      it { is_expected.to eq('ACME Inc.') }
    end
  end
end
