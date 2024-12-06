# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MessageWorker, type: :worker do
  subject(:worker) { described_class }

  let(:message) { create(:message) }

  describe '.call' do
    it 'schedules a background job' do
      expect { worker.call(message) }.to change(worker.jobs, :size).by(1)
    end
  end

  describe '#perform' do
    it 'invokes the Message::Send operation' do
      expect(Message::Send).to receive(:call).with(message)

      Sidekiq::Testing.inline! do
        worker.call(message)
      end
    end
  end
end
