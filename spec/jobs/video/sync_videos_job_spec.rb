# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Video::SyncVideosJob, type: :job do
  let(:provider) { create(:video_provider, :vimeo) }
  let(:full) { true }

  describe '#perform' do
    context 'when the provider is specified' do
      subject(:enqueue_job) do
        described_class.perform_later(provider: provider.id, full:)
      end

      it 'enqueues a new job' do
        expect { enqueue_job }.to have_enqueued_job(described_class).on_queue('long_running')
      end
    end

    context 'when the provider is not specified' do
      subject(:execute_job) do
        # Execute the (parent) job directly, so the enqueued jobs can be inspected.
        described_class.new.perform(full:)
      end

      before { create_list(:video_provider, 2, :vimeo) }

      it 'enqueues jobs for all providers' do
        expect { execute_job }.to have_enqueued_job(described_class).on_queue('long_running').twice
      end
    end

    context 'when the provider is not found' do
      subject(:enqueue_job) do
        described_class.perform_later(provider: SecureRandom.uuid, full:)
      end

      around {|example| perform_enqueued_jobs(&example) }

      it 'fails silently by ignoring the job' do
        expect { enqueue_job }.not_to raise_error
      end
    end
  end
end
