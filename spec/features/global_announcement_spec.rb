# frozen_string_literal: true

require 'spec_helper'

context 'OpenHPI: Global Announcement Mail', type: :job do
  include ActiveJob::TestHelper

  let(:author_id) { '00000001-3100-4444-9999-000000000002' }
  let(:richtext_id) { '00000001-3700-4444-9999-000000000025' }
  let(:user_kevin_language) { 'en' }
  let(:announcement_id) { '00000001-4300-4444-9999-000000000001' }
  let(:users) do
    %w[
      00000001-3100-4444-9999-000000000001
      00000001-3100-4444-9999-000000000002
    ]
  end
  let(:notification_disable_link_base) { 'https://xikolo.de/notification_user_settings/disable' }

  let(:message) do
    {
      id: announcement_id,
      title: {'en' => 'Test Title', 'de' => 'Test Titel'},
      author_id:,
      course_id: '',
      timestamp: Time.zone.now,
    }
  end

  before do
    clear_enqueued_jobs
    clear_performed_jobs

    # prepare mail for display
    # find author name
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000002'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000002',
      name: 'A. Admin',
      email: 'admin@example.com',
      language: 'en',
      emails_url: '/account_service/users/00000001-3100-4444-9999-000000000002/emails',
      features_url: '/account_service/users/00000001-3100-4444-9999-000000000002/features',
      preferences_url: '/account_service/users/00000001-3100-4444-9999-000000000002/preferences',
    })

    # find article text
    Stub.request(
      :news, :get, "/news/#{announcement_id}",
      query: {embed: 'translations'}
    ).to_return Stub.json({
      id: announcement_id,
      title: 'Test Title',
      text: '**bold** Click on https://www.example.com to learn more',
      language: 'en',
      available_languages: %w[en],
      translations: {},
      url: "/announcements/#{announcement_id}",
    })

    # find course
    Stub.request(
      :course, :get, '/courses/00000001-3300-4444-9999-000000000002'
    ).to_return Stub.json({
      id: '00000001-3300-4444-9999-000000000002',
      title: 'Geovisualisierung',
    })

    # find user_ids from confirmed users (first page)
    Stub.request(
      :account, :get, '/users',
      query: hash_including(confirmed: 'true')
    ).to_return Stub.json(
      users[0..].map {|id| {id:} },
      links: {
        next: 'http://localhost:3000/account_service/users/secondpage',
      }
    )
    # Second page of users
    Stub.request(
      :account, :get, '/users/secondpage'
    ).to_return Stub.json(
      users[1..].map {|id| {id:} }
    )

    # find user names and email addresses
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000001',
      display_name: 'Kevin Cool',
      email: 'kevin.cool@example.com',
      language: user_kevin_language,
      archived: false,
      emails_url: '/account_service/users/00000001-3100-4444-9999-000000000001/emails',
      features_url: '/account_service/users/00000001-3100-4444-9999-000000000001/features',
      preferences_url: '/account_service/users/00000001-3100-4444-9999-000000000001/preferences',
    })

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/preferences'
    ).to_return Stub.json({properties: {}})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000002/preferences'
    ).to_return Stub.json({properties: {}})

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/features'
    ).to_return Stub.json({})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000002/features'
    ).to_return Stub.json({})

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/emails'
    ).to_return Stub.json([
      {id: '00000009-9999-4444-9999-000000000001'},
    ])
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000002/emails'
    ).to_return Stub.json([
      {id: '00000009-9999-4444-9999-000000000004'},
    ])

    allow(I18n).to receive(:t).and_return('Subject')
  end

  context 'SendAnnouncementJob enqueuing' do
    before do
      NotificationService::AnnouncementJob.perform_later(message)

      perform_enqueued_jobs
    end

    it 'enqueues the correct number of SendAnnouncementJobs' do
      send_jobs = enqueued_jobs.select {|j| j[:job] == NotificationService::SendAnnouncementJob }
      expect(send_jobs.size).to eq(users.size)
    end
  end

  context 'checking the mail content' do
    before do
      perform_enqueued_jobs(
        only: [
          NotificationService::AnnouncementJob,
          NotificationService::SendAnnouncementJob,
        ]
      ) do
        NotificationService::AnnouncementJob.perform_later(message)
      end
    end

    it 'includes the openHPI footer' do
      mail = ActionMailer::Base.deliveries.last
      expect(mail).not_to be_nil
      expect(conv_str(mail.html_part)).to include('Prof. Dr. Tobias Friedrich')
        .and(include('Dr. Daniela Gerd tom Markotten'))
        .and(include('Dr. Henrik Haenecke'))
    end
  end
end
