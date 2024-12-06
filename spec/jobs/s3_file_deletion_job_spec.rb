# frozen_string_literal: true

require 'spec_helper'

describe S3FileDeletionJob, type: :job do
  subject(:enqueue_job) { described_class.perform_later(uri) }

  let(:uri) { 's3://xikolo-public/courses/34/image.jpg' }

  it 'enqueues a new job' do
    expect { enqueue_job }.to have_enqueued_job(described_class)
      .with('s3://xikolo-public/courses/34/image.jpg')
      .on_queue('default')
  end

  describe '#perform' do
    let!(:s3_delete_stub) do
      stub_request(:delete, 'https://s3.xikolo.de/xikolo-public/courses/34/image.jpg')
    end

    around {|example| perform_enqueued_jobs(&example) }

    it 'removes the S3 object' do
      enqueue_job
      expect(s3_delete_stub).to have_been_requested
    end

    context 'with blank URI' do
      let(:uri) { '' }

      it 'silently skips the deletion' do
        expect { enqueue_job }.not_to raise_error
      end
    end

    context 'with invalid bucket key in URI' do
      let(:uri) { 's3://invalid' }

      it 'silently skips the deletion' do
        expect { enqueue_job }.not_to raise_error
      end
    end
  end
end
