# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::RecipientWorker, type: :worker do
  subject(:worker) { described_class }

  let(:message) { create(:'news_service/message') }
  let(:recipient) { 'urn:x-xikolo:account:group:xikolo.active' }

  describe '::call' do
    it 'schedules a background job' do
      expect do
        worker.call(message, recipient)
      end.to change(worker.jobs, :size).by(1)

      expect(worker.jobs.last).to include 'args' => [message.id, recipient]
    end
  end

  describe '#perform' do
    context 'when message has no consents' do
      it 'invokes the Message::Deliver operation' do
        expect(NewsService::Message::Deliver).to receive(:call) do |*args|
          aggregate_failures 'operation arguments' do
            expect(args[0]).to eq message
            expect(args[1]).to be_a NewsService::Recipient::Group
          end
        end

        Sidekiq::Testing.inline! do
          worker.call(message, recipient)
        end
      end
    end

    context 'when message has consents' do
      let(:message) { create(:'news_service/message', consents: %w[treatment.marketing]) }

      it 'invokes the Message::Deliver operation with a decorated recipient object' do
        expect(NewsService::Message::Deliver).to receive(:call) do |*args|
          aggregate_failures 'operation arguments' do
            expect(args[0]).to eq message
            expect(args[1]).to be_a NewsService::FilterByConsents
          end
        end

        Sidekiq::Testing.inline! do
          worker.call(message, recipient)
        end
      end
    end
  end
end
