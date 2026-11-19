# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::MessageJob, type: :job do
  subject(:job) { described_class }

  let(:message) { create(:'news_service/message') }

  describe '#perform_later' do
    it 'schedules a background job' do
      expect { job.perform_later(message.id) }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end

    it 'enqueues the job with the correct message id' do
      expect { job.perform_later(message.id) }.to have_enqueued_job(job).with(message.id)
    end
  end

  describe '#perform' do
    it 'invokes the Message::Send operation' do
      expect(NewsService::Message::Send).to receive(:call) do |msg|
        expect(msg.id).to eq(message.id)
      end

      job.perform_now(message.id)
    end
  end
end
