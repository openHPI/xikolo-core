# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'News Email: Create (Send)', type: :request do
  include ActiveJob::TestHelper

  subject(:request) do
    perform_enqueued_jobs(only: NewsService::CourseAnnouncementJob) do
      news_resource.rel(:email).post(payload).value!
    end
  end

  let(:service) { restify_with_headers(news_service_url).get.value! }
  let(:news_resource) { service.rel(:news).get({id: announcement.id}).value! }
  let(:announcement) { create(:'news_service/news') }
  let(:payload) { {} }

  it { is_expected.to respond_with :created }

  it 'stores a record of sending this email' do
    expect do
      request
    end.to change { announcement.emails.count }.from(0).to(1)
  end

  it 'triggers an email to be sent' do
    expect { request }.to have_enqueued_job(NotificationService::AnnouncementJob)
  end

  context 'for a global announcement' do
    let(:announcement) { create(:'news_service/news', :global) }

    it 'publishes the correct event payload' do
      expect { request }
        .to have_enqueued_job(NotificationService::AnnouncementJob)
        .with(hash_including(course_id: nil))
    end
  end

  context 'for a group-restricted global announcement' do
    let(:announcement) { create(:'news_service/news', :global, audience: 'xikolo.affiliated') }

    it 'includes the group name in the event payload' do
      expect { request }
        .to have_enqueued_job(NotificationService::AnnouncementJob)
        .with(hash_including(course_id: nil, group: 'xikolo.affiliated'))
    end
  end

  context 'with explicit receiver for test email' do
    let(:receiver_id) { SecureRandom.uuid }
    let(:payload) { super().merge test_receiver: receiver_id }

    it { is_expected.to respond_with :created }

    it 'forwards the receiver ID' do
      expect { request }
        .to have_enqueued_job(NotificationService::AnnouncementJob)
        .with(hash_including(receiver_id:))
    end
  end
end
