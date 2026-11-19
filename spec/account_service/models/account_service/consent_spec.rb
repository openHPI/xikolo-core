# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccountService::Consent, type: :model do
  let(:attributes) { {} }
  let(:consent) { AccountService::Consent.create attributes }

  it { is_expected.to accept_values_for(:value, true, false) }

  it { is_expected.not_to accept_values_for(:value, nil) }

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

  describe '#consented_at' do
    it 'is based on creation time' do
      timestamp = 2.days.ago
      consent = create(:'account_service/consent', created_at: timestamp)

      expect(consent.consented_at).to eq timestamp
    end
  end
end
