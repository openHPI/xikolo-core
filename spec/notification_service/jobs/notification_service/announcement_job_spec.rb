# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::AnnouncementJob do
  subject(:perform_job) { described_class.perform_now(payload) }

  let(:news_id) { 'news-1' }
  let(:title) { {'en' => 'Hello'} }
  let(:payload) { {id: news_id, title: title} }

  let(:announcement_double) do
    instance_double(
      NotificationService::GlobalAnnouncement,
      id: news_id,
      key: 'news.announcement',
      notify_params: {subject: title, mail_log: true}
    )
  end

  let(:iterator_double) do
    instance_double(
      NotificationService::Audience::Iterator,
      first_page?: true,
      count: 2,
      next_page: nil
    )
  end

  before do
    allow(NotificationService::MailLog)
      .to receive(:queue_if_unsent!)
      .and_yield

    allow(NotificationService::GlobalAnnouncement)
      .to receive(:new)
      .and_return(announcement_double)

    allow(NotificationService::Audience::Iterator)
      .to receive(:new)
      .and_return(iterator_double)

    allow(iterator_double)
      .to receive(:each)
      .and_yield('user-1')
      .and_yield('user-2')
  end

  describe 'normal sending' do
    it 'enqueues SendAnnouncementJob for each user' do
      expect { perform_job }.to have_enqueued_job(NotificationService::SendAnnouncementJob).twice
    end
  end

  describe 'pagination' do
    let(:next_page_url) { 'next-url' }

    before do
      allow(iterator_double).to receive_messages(next_page: next_page_url, first_page?: false)
    end

    it 're-enqueues itself with next page' do
      expect { perform_job }
        .to have_enqueued_job(described_class)
        .with(payload.merge(page: next_page_url))
    end
  end

  describe 'test mode' do
    let(:payload) do
      {
        id: news_id,
        title: title,
        test: true,
        receiver_id: 'user-99',
      }
    end

    it 'enqueues a single SendAnnouncementJob with test flag' do
      expect { perform_job }
        .to have_enqueued_job(NotificationService::SendAnnouncementJob)
        .with(hash_including(
          receiver_id: 'user-99'
        ))
    end

    it 'does not iterate audience' do
      expect(iterator_double).not_to receive(:each)

      perform_job
    end
  end
end
