# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::AnnouncementWorker, type: :worker do
  subject(:worker) { described_class }

  let(:announcement) { create(:'news_service/announcement') }

  describe '.call' do
    it 'schedules a background job' do
      expect { worker.call(announcement) }.to change(worker.jobs, :size).by(1)
    end
  end

  describe '#perform' do
    it 'invokes Message::Create operation for given announcement' do
      expect(NewsService::Message::Create).to receive(:call).with(announcement)

      Sidekiq::Testing.inline! do
        worker.call(announcement)
      end
    end

    context 'with stale announcement' do
      it 'does not invoke operation' do
        expect(NewsService::Message::Create).not_to receive(:call)

        Sidekiq::Testing.inline! do
          # Run worker as if scheduled before the announcement has been
          # updated (or created in this case).
          worker.call(announcement,
            created_at: announcement.updated_at - 1.minute)
        end
      end
    end
  end
end
