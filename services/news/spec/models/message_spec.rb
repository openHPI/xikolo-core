# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Message, type: :model do
  subject(:message) { create(:message) }

  describe '(validations)' do
    context 'creator_id' do
      it { is_expected.to accept_values_for(:creator_id, SecureRandom.uuid) }
      it { is_expected.not_to accept_values_for(:creator_id, nil) }
    end

    context 'consents' do
      it { is_expected.to accept_values_for(:consents, %w[treatment.marketing treatment.other]) }
      it { is_expected.to accept_values_for(:consents, nil) }
      it { is_expected.to accept_values_for(:consents, []) }
    end
  end

  describe '(sanitization)' do
    it '#consents= only stores arrays of strings' do
      message.update(consents: [{foo: :bar}, 4])
      expect(message.consents).to eq []

      message.update(consents: 42)
      expect(message.consents).to eq []

      message.update(consents: %w[real consents])
      expect(message.consents).to eq %w[real consents]
    end
  end
end
