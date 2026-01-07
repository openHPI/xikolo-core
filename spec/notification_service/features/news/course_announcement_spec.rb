# frozen_string_literal: true

require 'spec_helper'

describe 'Course Announcement Mail', type: :feature do
  let(:user_id) { '00000001-3100-4444-9999-000000000002' }
  let(:course_id) { '00000001-3300-4444-9999-000000000002' }
  let(:kevins_properties) { {} }
  let(:announcement_id) { '00000001-4300-4444-9999-000000000001' }
  let(:enrolled_users) do
    %w[
      00000001-3100-4444-9999-000000000001
      00000001-3100-4444-9999-000000000003
      00000001-3100-4444-9999-000000000101
    ]
  end
  let(:notification_disable_link_base) { 'https://xikolo.de/notification_user_settings/disable' }

  let(:message) do
    {
      id: announcement_id,
      title: {'en' => 'Test Title', 'de' => 'Test Titel'},
      author_id: user_id,
      course_id:,
      timestamp: Time.zone.now,
    }
  end
  let(:publish) { -> { Msgr.publish(message, to: 'xikolo.news.announcement.create') } }

  before do
    Msgr.client.start

    Stub.service(:news, build(:'news:root'))

    Stub.request(
      :news, :get, "/news/#{announcement_id}",
      query: {embed: 'translations'}
    ).to_return Stub.json({
      id: announcement_id,
      title: 'Test Title',
      text: '**bold** Click on https://www.example.com to learn more',
      language: 'en',
      available_languages: %w[en de],
      translations: {
        de: {
          title: 'Test Titel',
          text: '**fett**',
        },
      },
      url: "/announcements/#{announcement_id}",
    })

    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(course_id: '00000001-3300-4444-9999-000000000002', per_page: 1)
    ).to_return Stub.response(headers: {
      'X-Total-Pages' => 3,
    })

    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(course_id: '00000001-3300-4444-9999-000000000002')
    ).to_return Stub.json(
      enrolled_users[0..1].map {|id| {user_id: id} },
      links: {
        next: 'http://localhost:3000/course_service/enrollments/secondpage',
      }
    )

    Stub.request(
      :course, :get, '/enrollments/secondpage'
    ).to_return Stub.json(enrolled_users[2..].map {|id| {user_id: id} })

    Stub.request(
      :course, :get, '/courses/00000001-3300-4444-9999-000000000002'
    ).to_return Stub.json({
      id: '00000001-3300-4444-9999-000000000002',
      title: 'A Course',
    })

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000001',
      name: 'Kevin Cool',
      email: 'kevin.cool@example.com',
      language: 'en',
      archived: false,
      emails_url: '/account_service/users/00000001-3100-4444-9999-000000000001/emails',
      features_url: '/account_service/users/00000001-3100-4444-9999-000000000001/features',
      preferences_url: '/account_service/users/00000001-3100-4444-9999-000000000001/preferences',
    })
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/preferences'
    ).to_return Stub.json({properties: kevins_properties})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/features'
    ).to_return Stub.json({})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/emails'
    ).to_return Stub.json([
      {id: '00000009-9999-4444-9999-000000000001'},
    ])

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000003',
      name: 'Tom T. Teacher',
      email: 'tom@example.com',
      language: 'de',
      archived: false,
      emails_url: '/account_service/users/00000001-3100-4444-9999-000000000003/emails',
      features_url: '/account_service/users/00000001-3100-4444-9999-000000000003/features',
      preferences_url: '/account_service/users/00000001-3100-4444-9999-000000000003/preferences',
    })
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003/preferences'
    ).to_return Stub.json({properties: {}})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003/features'
    ).to_return Stub.json({})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003/emails'
    ).to_return Stub.json([
      {id: '00000009-9999-4444-9999-000000000002'},
    ])

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000101',
      name: 'U_1 Smith',
      email: 'john.smith1@example.com',
      language: 'en',
      archived: false,
      emails_url: '/account_service/users/00000001-3100-4444-9999-000000000101/emails',
      features_url: '/account_service/users/00000001-3100-4444-9999-000000000101/features',
      preferences_url: '/account_service/users/00000001-3100-4444-9999-000000000101/preferences',
    })
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101/preferences'
    ).to_return Stub.json({properties: {}})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101/features'
    ).to_return Stub.json({})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101/emails'
    ).to_return Stub.json([
      {id: '00000009-9999-4444-9999-000000000003'},
    ])
  end

  it 'sends a mail to each enrolled user' do
    publish.call

    Msgr::TestPool.run count: 5

    expect(mails.size).to eq 3
    expect(mails.map {|m| m.to.first }).to match_array \
      %w[kevin.cool@example.com tom@example.com john.smith1@example.com]
    expect(conv_str(mail.html_part)).to include 'Test Title'
    expect(mail.subject).to eq 'Test Title: A Course'

    # Not a test mail
    expect(conv_str(mail.html_part)).not_to include 'This is a test message, only you received this!'

    # Links are tracked
    expect(conv_str(mail.text_part)).to include '&tracking_user=1YLgUE6KPhaxfpGX7'

    # URLs are linkified
    expect(conv_str(mail.html_part)).to include 'Click on <a href='
  end

  it 'sends email only once even on multiple send' do
    publish.call
    Msgr::TestPool.run count: 5
    publish.call
    expect { Msgr::TestPool.run(count: 5) }.to raise_error(Timeout::Error)
    expect(mails.size).to eq 3
  end

  context 'with deleted user' do
    let(:enrolled_users) do
      %w[
        00000001-3100-4444-9999-000000000001
        00000001-3100-4444-9999-000000000003
        00000001-3100-4444-9999-000000000101
        00000001-3100-4444-9999-000000000404
      ]
    end

    before do
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000404'
      ).to_return Stub.json({
        id: '00000001-3100-4444-9999-000000000404',
        name: 'Deleted User',
        email: nil,
        language: 'en',
        archived: true,
        emails_url: '/account_service/users/00000001-3100-4444-9999-000000000404/emails',
        features_url: '/account_service/users/00000001-3100-4444-9999-000000000404/features',
        preferences_url: '/account_service/users/00000001-3100-4444-9999-000000000404/preferences',
      })
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000404/preferences'
      ).to_return Stub.json({properties: {}})
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000404/features'
      ).to_return Stub.json({})
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000404/emails'
      ).to_return Stub.json([])
    end

    it 'sends email normally but ignores the deleted user' do
      publish.call
      Msgr::TestPool.run count: 6
      expect(mails.size).to eq 3

      api = restify_with_headers(notification_service_url).get.value!

      stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
      expect(stats['count']).to eq 4
      expect(stats['success_count']).to eq 3
      expect(stats['disabled_count']).to eq 1
      expect(stats['error_count']).to eq 0
    end
  end

  context 'when a mail for Kevin has already been sent' do
    before do
      NotificationService::MailLog.create(
        user_id: '00000001-3100-4444-9999-000000000001',
        news_id: announcement_id,
        course_id:,
        state: 'success',
        key: 'course.announcement'
      )
    end

    it 'does not send another mail to Kevin' do
      publish.call

      expect { Msgr::TestPool.run count: 5 }.to raise_error(Timeout::Error)

      expect(mails.size).to eq 2
      expect(mails.flat_map(&:to)).to match_array \
        %w[tom@example.com john.smith1@example.com]
    end
  end

  context 'when a mail for Kevin has been queued, but not yet sent' do
    before do
      NotificationService::MailLog.create(
        user_id: '00000001-3100-4444-9999-000000000001',
        news_id: announcement_id,
        state: 'queued'
      )
    end

    it 'does not send another mail to Kevin' do
      publish.call

      expect { Msgr::TestPool.run count: 5 }.to raise_error(Timeout::Error)

      expect(mails.size).to eq 2
      expect(mails.flat_map(&:to)).to match_array \
        %w[tom@example.com john.smith1@example.com]
    end
  end

  context 'Kevin has unsubscribed to course announcements' do
    let(:kevins_properties) { {'notification.email.course.announcement' => 'false'} }

    it 'excludes users who unsubscribed to course announcements in their settings' do
      publish.call

      Msgr::TestPool.run count: 5

      expect(mails.size).to eq 2
      expect(mails.flat_map(&:to)).to match_array \
        %w[tom@example.com john.smith1@example.com]
      expect(conv_str(mail.html_part)).to include 'Test Title'
      expect(mail.subject).to eq 'Test Title: A Course'
    end
  end

  it 'includes the course title' do
    publish.call
    Msgr::TestPool.run count: 5
    expect(conv_str(mail.html_part)).to include 'A Course'
  end

  context 'with translations' do
    it 'translates email\'s subject' do
      publish.call

      Msgr::TestPool.run count: 5

      english_mail = mails.find {|m| m.to[0].eql? 'kevin.cool@example.com' }
      german_mail = mails.find {|m| m.to[0].eql? 'tom@example.com' }
      french_mail = mails.find {|m| m.to[0].eql? 'john.smith1@example.com' }

      expect(english_mail.subject).to eq 'Test Title: A Course'
      expect(german_mail.subject).to eq 'Test Titel: A Course'
      # french is not in available locales,
      # so should fallback to default_locale (en)
      expect(french_mail.subject).to eq 'Test Title: A Course'
    end
  end

  it 'includes disable links' do
    publish.call
    Msgr::TestPool.run count: 5

    expect(mails.size).to eq 3

    expect(conv_str(mail.html_part)).to include mail.to.first
    expect(conv_str(mail.html_part)).to include notification_disable_link_base
  end

  it 'translates disable links' do
    publish.call
    Msgr::TestPool.run count: 5

    english_mail = mails.find {|m| m.to[0].eql? 'kevin.cool@example.com' }
    expect(conv_str(english_mail.html_part)).to include 'you are signed up at Xikolo with your address kevin.cool@example.com'
    expect(conv_str(english_mail.html_part)).to include 'receive further course announcements'
    expect(conv_str(english_mail.html_part)).to include 'receive any further emails at all'

    german_mail = mails.find {|m| m.to[0].eql? 'tom@example.com' }
    expect(conv_str(german_mail.html_part)).to include 'weil Sie mit Ihrer E-Mail-Adresse tom@example.com bei Xikolo'
    expect(conv_str(german_mail.html_part)).to include 'Kursmitteilungen mehr erhalten möchten'
    expect(conv_str(german_mail.html_part)).to include 'überhaupt keine Benachrichtigungen per E-Mail'
  end

  it 'sets text direction properly' do
    publish.call
    Msgr::TestPool.run count: 5

    # content body
    expect(mail.body.encoded).to include('<div dir=3D"auto">')

    # header title
    expect(mail.body.encoded)
      .to include('<p class=3D"template-label text-right" dir=3D"auto"')
  end

  it 'updates the mail log so that progress can be checked in the frontend' do
    publish.call

    api = restify_with_headers(notification_service_url).get.value!

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 0

    # Trigger notification events (page 1)
    Msgr::TestPool.run count: 1

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 2
    expect(stats['success_count']).to eq 0
    expect(stats['disabled_count']).to eq 0
    expect(stats['error_count']).to eq 0

    # Send the queued notification mails from page 1 and load page 2
    Msgr::TestPool.run count: 3

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 3
    expect(stats['success_count']).to eq 2
    expect(stats['disabled_count']).to eq 0
    expect(stats['error_count']).to eq 0

    # Send the remaining queued notification mail from page 2
    Msgr::TestPool.run count: 1

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 3
    expect(stats['success_count']).to eq 3
    expect(stats['disabled_count']).to eq 0
    expect(stats['error_count']).to eq 0
  end

  context 'as test mail' do
    let(:message) { super().merge test: true }

    before do
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000002'
      ).to_return Stub.json({
        id: '00000001-3100-4444-9999-000000000002',
        name: 'Adam Author',
        email: 'adam@example.org',
        language: 'en',
        emails_url: '/account_service/users/00000001-3100-4444-9999-000000000002/emails',
        features_url: '/account_service/users/00000001-3100-4444-9999-000000000002/features',
        preferences_url: '/account_service/users/00000001-3100-4444-9999-000000000002/preferences',
      })
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000002/preferences'
      ).to_return Stub.json({properties: {}})
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000002/features'
      ).to_return Stub.json({})
      Stub.request(
        :account, :get, '/users/00000001-3100-4444-9999-000000000002/emails'
      ).to_return Stub.json([
        {id: '00000009-9999-4444-9999-000000000001'},
      ])
    end

    it 'sends mail only to author' do
      publish.call

      Msgr::TestPool.run count: 2

      expect(mails.size).to eq 1
      expect(mails.map(&:to).flatten.join).to eq 'adam@example.org'
      expect(conv_str(mail.html_part)).to include 'This is a test message, only you received this!'
    end
  end

  context 'based on config' do
    before do
      xi_config <<~YML
        site_name: 'XiMOOCs'
        mailsender: 'foo@bar.com'
      YML
      publish.call
      Msgr::TestPool.run count: 5
    end

    it 'includes the platform name in the disable link' do
      expect(conv_str(mail.html_part)).to include 'because you are signed up at XiMOOCs'
    end

    it 'sends from the configured email address' do
      expect(mail.from).to eq(['foo@bar.com'])
    end
  end
end
