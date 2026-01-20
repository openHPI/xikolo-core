# frozen_string_literal: true

require 'spec_helper'

describe 'OpenHPI: Course Announcement' do
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

  let(:notification_disable_link_base) { 'https://xikolo.de/notification_user_settings/disable' }

  before do
    Msgr.client.start

    Stub.service(:news, build(:'news:root'))
    Stub.service(:course, build(:'course:root'))

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
          text: '**fett** Klicken Sie auf https://www.example.com, um mehr zu lernen',
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
      email: 'tom@openhpi.de',
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
      language: 'de',
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

    # Sender account
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

    publish.call
    Msgr::TestPool.run count: 5
  end

  it 'includes the openHPI footer' do
    # check only for content that is available in all languages
    expect(conv_str(mail.html_part)).to include('Prof. Dr. Tobias Friedrich')
  end
end
