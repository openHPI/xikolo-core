# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeEffortJob, type: :model do
  subject(:create_job) { time_effort_job }

  let(:item) { create(:item) }
  let(:time_effort_job) { create(:time_effort_job, item:) }

  it 'creates a new item' do
    expect(create_job.id).not_to be_nil
  end

  describe 'cancel_active_jobs callback' do
    it 'marks the existing job as canceled' do
      expect do
        create(:time_effort_job, item:)
      end.to change { time_effort_job.reload.status }.from('waiting').to('cancelled')
    end
  end

  describe '#schedule' do
    subject(:schedule_job) { time_effort_job.schedule }

    it 'enqueues a new job' do
      expect { schedule_job }.to have_enqueued_job(CalculateTimeEffortJob).with(time_effort_job.id)
    end

    it 'sets the job id' do
      expect { schedule_job }.to change(time_effort_job, :job_id).from(nil)
    end
  end

  describe '#start' do
    subject(:start_job) { time_effort_job.start }

    context 'w/o job cancelled' do
      it 'marks the TimeEffortJob as started' do
        expect { start_job }.to change { time_effort_job.reload.status }.from('waiting').to('started')
      end
    end

    context 'w/ job cancelled' do
      let(:time_effort_job) { create(:time_effort_job, :cancelled) }

      it 'does not mark the TimeEffortJob as started' do
        expect { start_job }.not_to change { time_effort_job.reload.status }
      end
    end
  end

  describe '#cancel' do
    subject(:cancel_job) { time_effort_job.cancel }

    it 'cancels the job' do
      expect { cancel_job }.to change { time_effort_job.reload.status }.from('waiting').to('cancelled')
    end

    context 'w/ enqueued CalculateTimeEffortJob' do
      before do
        time_effort_job.schedule
      end

      it 'removes the job from the queue' do
        expect { cancel_job }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.from(1).to(0)
      end

      it 'destroys the TimeEffortJob' do
        expect { cancel_job }.to change(described_class, :count).from(1).to(0)
      end
    end
  end

  describe '#calculation_processor' do
    subject(:processor) { time_effort_job.calculation_processor }

    let(:item) { create(:item) }
    let(:time_effort_job) { create(:time_effort_job, item:) }

    it 'returns a processor' do
      expect(processor).to be_a(Processors::BaseProcessor)
    end

    context 'w/ richtext item' do
      let(:item) { create(:item, content_type: 'rich_text') }

      it 'returns the correct processor for rich texts' do
        expect(processor).to be_an_instance_of(Processors::RichTextProcessor)
      end
    end

    context 'w/ video item' do
      let(:item) { create(:item, content_type: 'video') }

      it 'returns the correct processor for rich texts' do
        expect(processor).to be_an_instance_of(Processors::VideoProcessor)
      end
    end

    context 'w/ quiz item' do
      let(:item) { create(:item, content_type: 'quiz') }

      it 'returns the correct processor for rich texts' do
        expect(processor).to be_an_instance_of(Processors::QuizProcessor)
      end
    end
  end

  describe '#cancel_active_jobs' do
    subject(:cancel_jobs) { described_class.cancel_active_jobs time_effort_job.item_id }

    let(:time_effort_job) { create(:time_effort_job, item:) }

    context 'w/ job waiting' do
      it 'marks the waiting job as canceled' do
        expect do
          cancel_jobs
        end.to change { time_effort_job.reload.status }.from('waiting').to('cancelled')
      end
    end

    context 'w/ job started' do
      let(:time_effort_job) { create(:time_effort_job, :started, item:) }

      it 'marks the started job as canceled' do
        expect do
          cancel_jobs
        end.to change { time_effort_job.reload.status }.from('started').to('cancelled')
      end
    end

    context 'w/ job cancelled' do
      let(:time_effort_job) { create(:time_effort_job, :cancelled, item:) }

      it 'does not cancel the already cancelled job' do
        expect do
          cancel_jobs
        end.not_to change { time_effort_job.reload.status }
      end
    end
  end
end
