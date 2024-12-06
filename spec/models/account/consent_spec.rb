# frozen_string_literal: true

require 'spec_helper'

describe Account::Consent, type: :model do
  subject(:resource) { consent }

  let(:consent) { create(:consent) }

  it { is_expected.to accept_values_for :value, true, false }

  it { is_expected.not_to accept_values_for :value, nil }

  describe '#consented?' do
    context 'consent is given' do
      let(:consent) { create(:consent, :consented) }

      it { is_expected.to be_consented }
    end

    context 'consent is refused' do
      let(:consent) { create(:consent, :refused) }

      it { is_expected.not_to be_consented }
    end
  end

  describe '#refused?' do
    context 'consent is given' do
      let(:consent) { create(:consent, :consented) }

      it { is_expected.not_to be_refused }
    end

    context 'consent is refused' do
      let(:consent) { create(:consent, :refused) }

      it { is_expected.to be_refused }
    end
  end
end
