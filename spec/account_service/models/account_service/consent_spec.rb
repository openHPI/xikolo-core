# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccountService::Consent, type: :model do
  let(:attributes) { {} }
  let(:consent) { AccountService::Consent.create attributes }

  describe '#consented?' do
    subject { consent.consented? }

    context 'consent is given' do
      let(:attributes) { {value: true} }

      it { is_expected.to be_truthy }
    end

    context 'consent is refused' do
      let(:attributes) { {value: false} }

      it { is_expected.to be_falsey }
    end

    context 'consent is neither given nor refused' do
      let(:attributes) { {value: nil} }

      it { is_expected.to be_falsey }
    end
  end

  describe '#refused?' do
    subject { consent.refused? }

    context 'consent is given' do
      let(:attributes) { {value: true} }

      it { is_expected.to be false }
    end

    context 'consent is refused' do
      let(:attributes) { {value: false} }

      it { is_expected.to be true }
    end

    context 'consent is neither given nor refused' do
      let(:attributes) { {value: nil} }

      it { is_expected.to be false }
    end
  end
end
