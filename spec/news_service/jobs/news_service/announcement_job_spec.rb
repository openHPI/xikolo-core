# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::AnnouncementJob, type: :job do
  subject(:job) { described_class }

  let(:announcement) { create(:'news_service/announcement') }

  describe '.call' do
    it 'schedules a background job' do
      expect { job.call(announcement) }.to have_enqueued_job(job).exactly(:once)
    end
  end

  describe '#perform' do
    it 'invokes Message::Create operation for given announcement' do
      expect(NewsService::Message::Create).to receive(:call).with(announcement)

      perform_enqueued_jobs do
        job.call(announcement)
      end
    end

    context 'with stale announcement' do
      it 'does not invoke operation' do
        expect(NewsService::Message::Create).not_to receive(:call)

        perform_enqueued_jobs do
          # Run job as if scheduled before the announcement has been
          # updated (or created in this case).
          job.call(announcement,
            created_at: announcement.updated_at - 1.minute)
        end
      end
    end
  end
end
