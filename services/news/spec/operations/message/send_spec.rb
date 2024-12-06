# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Message::Send, type: :operation do
  subject(:op) { described_class }

  let(:recipients) { ['user:john', 'group:active'] }
  let(:message) { create(:message, recipients:) }

  describe '::call' do
    it 'invokes a recipient worker for each recipient' do
      expect(RecipientWorker).to receive(:call).with(message, recipients[0])
      expect(RecipientWorker).to receive(:call).with(message, recipients[1])

      op.call(message)
    end
  end
end
