# frozen_string_literal: true

require 'spec_helper'

describe Recipient, type: :model do
  let(:message) { create(:message) }

  describe '::find' do
    subject(:recipient) { described_class.find(id, message) }

    context 'with user URN' do
      let(:id) do
        'urn:x-xikolo:account:user:b9f2f314-70aa-4c6b-bda1-e996d069a238'
      end

      it { is_expected.to be_a Recipient::User }
      it { expect(recipient.id).to eq 'b9f2f314-70aa-4c6b-bda1-e996d069a238' }

      context 'when message has consents' do
        let(:message) { create(:message, consents: %w[treatment.marketing]) }

        it { is_expected.to be_a FilterByConsents }
      end
    end

    context 'with group URN' do
      let(:id) do
        'urn:x-xikolo:account:group:xikolo.all'
      end

      it { is_expected.to be_a Recipient::Group }
      it { expect(recipient.id).to eq 'xikolo.all' }

      context 'when message has consents' do
        let(:message) { create(:message, consents: %w[treatment.marketing]) }

        it { is_expected.to be_a FilterByConsents }
      end
    end
  end
end
