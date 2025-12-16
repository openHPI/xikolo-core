# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::Message::Send, type: :operation do
  subject(:op) { described_class }

  let(:recipients) { ['user:john', 'group:active'] }
  let(:message) { create(:'news_service/message', recipients:) }

  describe '::call' do
    it 'invokes a recipient worker for each recipient' do
      expect(NewsService::RecipientWorker).to receive(:call).with(message, recipients[0])
      expect(NewsService::RecipientWorker).to receive(:call).with(message, recipients[1])

      op.call(message)
    end
  end
end
