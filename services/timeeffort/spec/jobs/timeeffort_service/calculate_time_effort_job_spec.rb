# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeeffortService::CalculateTimeEffortJob, type: :job do
  subject(:execute_job) { perform_enqueued_jobs { enqueue_job } }

  let(:item) { create(:'timeeffort_service/item') }
  let!(:time_effort_job) { create(:'timeeffort_service/time_effort_job', item:) }
  let(:key) { time_effort_job.id }
  let(:calculation_processor) { instance_double(TimeeffortService::Processors::BaseProcessor) }
  let(:enqueue_job) { described_class.perform_later(key) }

  let(:skip_callback!) do
    described_class.skip_callback(:perform, :after, :remove_time_effort_job_record)
  end

  after do
    described_class.set_callback(:perform, :after, :remove_time_effort_job_record)
  end

  before do
    allow(TimeeffortService::TimeEffortJob).to receive(:find).and_call_original
    allow(TimeeffortService::TimeEffortJob).to receive(:find).with(time_effort_job.id).and_return(time_effort_job)
    allow(time_effort_job).to receive(:calculation_processor).and_return(calculation_processor)
    allow(calculation_processor).to receive(:load_resources!)
    allow(calculation_processor).to receive(:calculate)
    allow(calculation_processor).to receive(:patch_items!)
  end

  it 'enqueues a new job' do
    expect { enqueue_job }.to have_enqueued_job(described_class)
      .with(key)
      .on_queue('default')
  end

  it 'attempts to mark TimeEffortJob as started' do
    expect(time_effort_job).to receive(:start).once

    execute_job
  end

  it 'deletes the job record after job execution' do
    expect { execute_job }.to change(TimeeffortService::TimeEffortJob, :count).from(1).to(0)
  end

  describe '#perform' do
    before { skip_callback! }

    context 'w/o job execution cancelled' do
      it 'tries to load resources' do
        expect(calculation_processor).to receive(:load_resources!).once
        execute_job
      end

      it 'calculates the time effort' do
        expect(calculation_processor).to receive(:calculate).once
        execute_job
      end

      it 'tries to patch items' do
        expect(calculation_processor).to receive(:patch_items!).once
        execute_job
      end
    end

    context 'w/ job execution cancelled' do
      let(:time_effort_job) { create(:'timeeffort_service/time_effort_job', :cancelled, item:) }

      it 'skips loading of resources' do
        expect(calculation_processor).not_to receive(:load_resources!)
        execute_job
      end

      it 'skips time effort calculation' do
        expect(calculation_processor).not_to receive(:calculate)
        execute_job
      end

      it 'skips patching items' do
        expect(calculation_processor).not_to receive(:patch_items!)
        execute_job
      end
    end

    context 'w/ not existing TimeEffortJob' do
      let(:key) { '11111111-1111-1111-9999-000000000001' }

      it 'fails silently by ignoring the job' do
        expect { execute_job }.not_to raise_error
      end
    end

    context 'w/ missing shadow item for the TimeEffortJob' do
      before do
        # Delete the corresponding item *right after* the job was started
        allow(time_effort_job).to receive(:start).and_wrap_original do |m, *args|
          m.call(*args)
          item.destroy!
        end
      end

      it 'aborts the processor execution' do
        expect(time_effort_job).not_to receive(:calculation_processor)
        execute_job
      end
    end
  end
end
