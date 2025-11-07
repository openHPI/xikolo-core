# frozen_string_literal: true

require 'spec_helper'

describe 'Global Announcement Mail', type: :feature do
  let(:author_id) { '00000001-3100-4444-9999-000000000002' }
  let(:richtext_id) { '00000001-3700-4444-9999-000000000025' }
  let(:user_kevin_language) { 'en' }
  let(:announcement_id) { '00000001-4300-4444-9999-000000000001' }
  let(:users) do
    %w[
      00000001-3100-4444-9999-000000000001
      00000001-3100-4444-9999-000000000002
      00000001-3100-4444-9999-000000000003
      00000001-3100-4444-9999-000000000101
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
  let(:publish) { -> { Msgr.publish(message, to: 'xikolo.news.announcement.create') } }

  before do
    Msgr.client.start

    # prepare mail for display
    # find author name
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000002'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000002',
      name: 'A. Admin',
      email: 'admin@example.com',
      language: 'en',
      emails_url: '/users/00000001-3100-4444-9999-000000000002/emails',
      features_url: '/users/00000001-3100-4444-9999-000000000002/features',
      preferences_url: '/users/00000001-3100-4444-9999-000000000002/preferences',
    })

    Stub.service(:news, build(:'news:root'))

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
      users[0..2].map {|id| {id:} },
      links: {
        next: 'http://localhost:3100/users/secondpage',
      }
    )
    # Second page of users
    Stub.request(
      :account, :get, '/users/secondpage'
    ).to_return Stub.json(
      users[3..].map {|id| {id:} }
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
      emails_url: '/users/00000001-3100-4444-9999-000000000001/emails',
      features_url: '/users/00000001-3100-4444-9999-000000000001/features',
      preferences_url: '/users/00000001-3100-4444-9999-000000000001/preferences',
    })
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000003',
      display_name: 'Tom T. Teacher',
      email: 'tom@example.com',
      language: 'en',
      archived: false,
      emails_url: '/users/00000001-3100-4444-9999-000000000003/emails',
      features_url: '/users/00000001-3100-4444-9999-000000000003/features',
      preferences_url: '/users/00000001-3100-4444-9999-000000000003/preferences',
    })
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000101',
      display_name: 'U_1 Smith',
      email: 'john.smith1@example.com',
      language: 'en',
      archived: false,
      emails_url: '/users/00000001-3100-4444-9999-000000000101/emails',
      features_url: '/users/00000001-3100-4444-9999-000000000101/features',
      preferences_url: '/users/00000001-3100-4444-9999-000000000101/preferences',
    })

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/preferences'
    ).to_return Stub.json({properties: {}})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000002/preferences'
    ).to_return Stub.json({properties: {}})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003/preferences'
    ).to_return Stub.json({properties: {}})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101/preferences'
    ).to_return Stub.json({properties: {}})

    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000001/features'
    ).to_return Stub.json({})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000002/features'
    ).to_return Stub.json({})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003/features'
    ).to_return Stub.json({})
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101/features'
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
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003/emails'
    ).to_return Stub.json([
      {id: '00000009-9999-4444-9999-000000000002'},
    ])
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000101/emails'
    ).to_return Stub.json([
      {id: '00000009-9999-4444-9999-000000000003'},
    ])

    # With `require_enrollment` config, check whether the users
    # had any enrollments (incl. deleted).
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(deleted: 'true', user_id: '00000001-3100-4444-9999-000000000001')
    ).to_return Stub.json([]) # no enrollments -> no email
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(deleted: 'true', user_id: '00000001-3100-4444-9999-000000000002')
    ).to_return Stub.json([
      {id: SecureRandom.uuid},
    ])
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(deleted: 'true', user_id: '00000001-3100-4444-9999-000000000003')
    ).to_return Stub.json([
      {id: SecureRandom.uuid},
    ])
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(deleted: 'true', user_id: '00000001-3100-4444-9999-000000000101')
    ).to_return Stub.json([
      {id: SecureRandom.uuid},
      {id: SecureRandom.uuid},
    ])
  end

  it 'sends email' do
    publish.call

    Msgr::TestPool.run count: 6

    expect(mails.size).to eq 4
    expect(mails.map {|m| m.to.first }).to match_array \
      %w[admin@example.com kevin.cool@example.com
         tom@example.com john.smith1@example.com]
    expect(mail.html).to include 'Test Title'
    expect(mail.subject).to include 'Test Title'

    expect(mail.subject).not_to include 'You are receiving this email because'

    # Not a test mail
    expect(mail.html).not_to include 'This is a test message, only you received this!'

    # Links are tracked
    expect(mail.text).to include '&tracking_user=1YLgUE6KPhaxfpGX7'

    # URLs are linkified
    expect(mail.html).to include 'Click on <a href='

    expect(mail.header['Precedence'].value).to eq 'bulk'
    expect(mail.header['Auto-Submitted'].value).to eq 'auto-generated'

    expect(mail.header['List-Unsubscribe'].value).to eq '<https://xikolo.de/notification_user_settings/disable?email=john.smith1%40example.com&hash=a7b19060600e9cf6767ce34c269febdfc9cd70ce58111c3a45dee4d5d77cd284&key=announcement>'
  end

  it 'sends email only once even on multiple send' do
    publish.call
    Msgr::TestPool.run count: 6
    publish.call
    expect { Msgr::TestPool.run(count: 6) }.to raise_error(Timeout::Error)
    expect(mails.size).to eq 4
  end

  context 'with deleted user' do
    let(:users) do
      %w[
        00000001-3100-4444-9999-000000000001
        00000001-3100-4444-9999-000000000002
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
        language: 'de',
        archived: true,
        emails_url: '/users/00000001-3100-4444-9999-000000000404/emails',
        features_url: '/users/00000001-3100-4444-9999-000000000404/features',
        preferences_url: '/users/00000001-3100-4444-9999-000000000404/preferences',
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
      Msgr::TestPool.run count: 7
      expect(mails.size).to eq 4

      api = Restify.new(:test).get.value!

      stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
      expect(stats['count']).to eq 5
      expect(stats['success_count']).to eq 4
      expect(stats['disabled_count']).to eq 1
      expect(stats['error_count']).to eq 0
    end
  end

  it 'includes a disable link' do
    publish.call
    Msgr::TestPool.run count: 6

    expect(mails.size).to eq 4
    expect(mail.html).to include mail.to.first
    expect(mail.html).to include notification_disable_link_base
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

  describe 'enrollment constraint' do
    context 'only sending to users who have been enrolled once' do
      before do
        Xikolo.config.announcements['require_enrollment'] = true
      end

      it 'only sends emails to users who enrolled to at least one course' do
        publish.call
        Msgr::TestPool.run count: 5

        expect(mails.size).to eq 3
        expect(mails.flat_map(&:to)).not_to include 'kevin.cool@example.com'
      end
    end

    context 'for platforms without the constraint' do
      it 'sends emails to all users, whether they have enrollments or not' do
        publish.call
        Msgr::TestPool.run count: 6

        expect(mails.size).to eq 4
        expect(mails.flat_map(&:to)).to include 'kevin.cool@example.com'
      end
    end
  end

  context 'with translations' do
    let(:user_kevin_language) { 'de' }

    it 'translates email\'s subject' do
      publish.call

      Msgr::TestPool.run count: 6

      english_mail = mails.find {|m| m.to[0].eql? 'tom@example.com' }
      german_mail = mails.find {|m| m.to[0].eql? 'kevin.cool@example.com' }

      expect(english_mail.subject).to include 'Test Title'
      expect(german_mail.subject).to include 'Test Titel'
    end

    it 'translates disable links' do
      publish.call
      Msgr::TestPool.run count: 6

      english_mail = mails.find {|m| m.to[0].eql? 'tom@example.com' }
      expect(english_mail.html).to include 'you are signed up at Xikolo with your address tom@example.com'
      expect(english_mail.html).to include 'receive further announcements'
      expect(english_mail.html).to include 'receive any further emails at all'

      german_mail = mails.find {|m| m.to[0].eql? 'kevin.cool@example.com' }
      expect(german_mail.html).to include 'weil Sie mit Ihrer E-Mail-Adresse kevin.cool@example.com bei Xikolo'
      expect(german_mail.html).to include 'Mitteilungen mehr erhalten möchten'
      expect(german_mail.html).to include 'überhaupt keine Benachrichtigungen per E-Mail'
    end
  end

  it 'updates the mail log so that progress can be checked in the frontend' do
    publish.call

    api = Restify.new(:test).get.value!

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 0

    # Trigger notification events (page 1)
    Msgr::TestPool.run count: 1

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 3
    expect(stats['success_count']).to eq 0
    expect(stats['disabled_count']).to eq 0
    expect(stats['error_count']).to eq 0

    # Send the queued notification mails from page 1 and load page 2
    Msgr::TestPool.run count: 4

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 4
    expect(stats['success_count']).to eq 3
    expect(stats['disabled_count']).to eq 0
    expect(stats['error_count']).to eq 0

    # Send the remaining queued notification mail from page 2
    Msgr::TestPool.run count: 1

    stats = api.rel(:mail_log_stats).get({news_id: announcement_id}).value!
    expect(stats['count']).to eq 4
    expect(stats['success_count']).to eq 4
    expect(stats['disabled_count']).to eq 0
    expect(stats['error_count']).to eq 0
  end

  context 'as test mail' do
    let(:message) { super().merge test: true }

    before do
      Stub.request(
        :account, :get, "/users/#{test_receiver_id}/preferences"
      ).to_return Stub.json({properties: {}})
      Stub.request(
        :account, :get, "/users/#{test_receiver_id}/features"
      ).to_return Stub.json({})
      Stub.request(
        :account, :get, "/users/#{test_receiver_id}/emails"
      ).to_return Stub.json([
        {id: '00000009-9999-4444-9999-000000000001'},
      ])
    end

    context 'without an explicit test receiver' do
      let(:test_receiver_id) { author_id }

      before do
        Stub.request(
          :account, :get, "/users/#{author_id}"
        ).to_return Stub.json({
          id: author_id,
          name: 'Adam Author',
          email: 'adam@example.org',
          language: 'en',
          archived: false,
          emails_url: "/users/#{author_id}/emails",
          features_url: "/users/#{author_id}/features",
          preferences_url: "/users/#{author_id}/preferences",
        })
      end

      it 'sends mail only to author' do
        publish.call

        Msgr::TestPool.run count: 2

        expect(mails.size).to eq 1
        expect(mails.map(&:to).flatten.join).to eq 'adam@example.org'
        expect(mail.html).to include 'This is a test message, only you received this!'
      end
    end

    context 'with explicit test receiver' do
      let(:test_receiver_id) { other_user_id }
      let(:other_user_id) { SecureRandom.uuid }
      let(:message) { super().merge receiver_id: other_user_id }

      before do
        Stub.request(
          :account, :get, "/users/#{other_user_id}"
        ).to_return Stub.json({
          id: other_user_id,
          name: 'Robert Receiver',
          email: 'robert@example.org',
          language: 'en',
          archived: false,
          emails_url: "/users/#{other_user_id}/emails",
          features_url: "/users/#{other_user_id}/features",
          preferences_url: "/users/#{other_user_id}/preferences",
        })
      end

      it 'sends a mail only to the defined test receiver' do
        publish.call

        Msgr::TestPool.run count: 2

        expect(mails.size).to eq 1
        expect(mails.map(&:to).flatten.join).to eq 'robert@example.org'
        expect(mail.html).to include 'This is a test message, only you received this!'
      end
    end
  end

  context 'based on config' do
    before do
      Xikolo.config.site_name = 'XiMOOCs'
      Xikolo.config.mailsender = 'foo@bar.com'
      publish.call
      Msgr::TestPool.run count: 5
    end

    it 'includes the standard header' do
      expect(mail.html).to include('alt="XiMOOCs logo"')
    end

    it 'sends from the configured email address' do
      expect(mail.from).to eq(['foo@bar.com'])
    end
  end
end
