# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Announcement: Create Email', gen: 2, type: :feature do
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }
  let(:announcement_id) { SecureRandom.uuid }
  let(:announcement) do
    {
      id: announcement_id,
      title: 'This might interest you',
      translations: {'en' => {
        'subject' => 'This might interest you',
        'content' => 'Check it out!',
      }},
      recipients: [],
      publication_channels: {email: nil},
      author_id: user_id,
      created_at: 1.day.ago,
      self_url: "/announcements/#{announcement_id}",
      messages_url: "/announcements/#{announcement_id}/messages",
    }
  end

  before do
    stub_user id: user_id, permissions: %w[news.announcement.create news.announcement.send], features: {'admin_announcements' => 'true'}
    Stub.service(:course, build(:'course:root'))
    Stub.service(:news, build(:'news:root'))

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)

    Stub.request(
      :course, :get, '/api/v2/course/courses',
      query: hash_including({})
    ).to_return Stub.json([])

    Stub.request(:news, :get, "/announcements/#{announcement_id}")
      .and_return Stub.json(announcement)
    Stub.request(:news, :get, '/announcements')
      .and_return Stub.json([announcement])

    # Custom-select ajax requests
    Stub.request(
      :account, :get, '/users',
      query: hash_including({})
    ).to_return Stub.json([
      {id: user_id, name: 'Some User', email: 'some.user@example.com'},
    ])
    Stub.request(
      :course, :get, '/courses',
      query: hash_including({groups: 'any'})
    ).to_return Stub.json([
      {course_code: 'some-course'},
      {title: 'Another Course', course_code: 'another-course'},
    ])
    Stub.request(
      :account, :get, '/groups',
      query: {tag: 'access'}
    ).to_return Stub.json([
      {name: 'xikolo.affiliated', description: 'Affiliated users'},
      {name: 'xikolo.partner', description: 'Partners'},
    ])
    Stub.request(:account, :get, '/treatments')
      .to_return Stub.json([{name: 'marketing'}])
    # Searches that aren't related to courses
    # shouldn't return any content test groups from the endpoint
    Stub.request(
      :account, :get, '/groups',
      query: hash_including({tag: 'content_test'})
    ).to_return Stub.json([])
    # Simulating two existing content test groups
    Stub.request(
      :account, :get, '/groups',
      query: hash_including({prefix: 'course.cloud2013', tag: 'content_test'})
    ).to_return Stub.json([
      {name: 'course.cloud2013.content_test.gamification.with-game'},
      {name: 'course.cloud2013.content_test.gamification.without-game'},
    ])
    Stub.request(
      :account, :get, '/groups',
      query: hash_including({tag: 'custom_recipients'})
    ).to_return Stub.json([
      {name: 'announcement.recipients.custom'},
    ])
  end

  it 'prefills, adjusts, and publishes the email announcement' do
    visit "/admin/announcements/#{announcement_id}/email/new"

    within_fieldset('English') do
      expect(page).to have_field('Subject', with: 'This might interest you')
      expect(page).to have_markdown_editor('Content', with: 'Check it out!')
    end

    within_fieldset('English') do
      fill_in 'Subject', with: 'News: This might interest you'
      fill_markdown_editor 'Content', with: 'Dear users, please check it out!'
    end
    tom_select 'Some User', from: 'Recipients', search: true
    tom_select 'some-course', from: 'Recipients', search: true
    tom_select 'Another Course', from: 'Recipients', search: true
    tom_select 'Affiliated users', from: 'Recipients', search: true
    tom_select 'with-game', from: 'Recipients', search: 'cloud2013'
    tom_select 'announcement.recipients.custom', from: 'Recipients', search: 'custom'
    check 'marketing'

    send_announcement = Stub.request(:news, :post, "/announcements/#{announcement_id}/messages")
      .to_return(status: 201)

    click_link_or_button 'Send announcement email'

    # Since there is no flash message when an announcement has been
    # created, we check that the new announcement is visible on the page
    # (listed under "Published").
    expect(page).to have_content 'This might interest you'

    expect(
      send_announcement.with(
        body: hash_including(
          'recipients' => [
            "urn:x-xikolo:account:user:#{user_id}",
            'urn:x-xikolo:account:group:course.some-course.students',
            'urn:x-xikolo:account:group:course.another-course.students',
            'urn:x-xikolo:account:group:xikolo.affiliated',
            'urn:x-xikolo:account:group:course.cloud2013.content_test.gamification.with-game',
            'urn:x-xikolo:account:group:announcement.recipients.custom',
          ],
          'creator_id' => user_id,
          'test' => false,
          'consents' => %w[treatment.marketing],
          'translations' => {
            'en' => {
              'subject' => 'News: This might interest you',
              'content' => 'Dear users, please check it out!',
            },
          }
        )
      )
    ).to have_been_requested
  end

  context 'with predefined recipients' do
    let(:announcement) do
      super().merge(recipients: [
        "urn:x-xikolo:account:user:#{user_id}",
        'urn:x-xikolo:account:group:some.group.1',
        'urn:x-xikolo:account:group:course.another-course.students',
      ])
    end

    before do
      Stub.request(:account, :get, "/users/#{user_id}")
        .to_return Stub.json({
          id: user_id,
          name: 'Some User',
          email: 'some.user@example.com',
        })
      Stub.request(:account, :get, '/groups/some.group.1')
        .to_return Stub.json({
          name: 'some.group.1',
          description: 'Some Group',
        })
      Stub.request(:account, :get, '/groups/course.another-course.students')
        .to_return Stub.json({
          name: 'course.another-course',
        })
      create(:course, course_code: 'another-course', title: 'Another Course')
    end

    it 'prefills, adjusts, and publishes the email announcement' do
      visit "/admin/announcements/#{announcement_id}/email/new"

      within_fieldset('English') do
        expect(page).to have_field('Subject', with: 'This might interest you')
        expect(page).to have_markdown_editor('Content', with: 'Check it out!')
      end

      within_fieldset('English') do
        fill_in 'Subject', with: 'News: This might interest you'
        fill_markdown_editor 'Content', with: 'Dear users, please check it out!'
      end
      tom_select 'some-course', from: 'Recipients', search: true
      check 'marketing'

      send_announcement = Stub.request(:news, :post, "/announcements/#{announcement_id}/messages")
        .to_return(status: 201)

      click_link_or_button 'Send announcement email'

      # Since there is no flash message when an announcement has been
      # sent out, we check that the (original) announcement is still visible
      # on the page (listed under "Published").
      expect(page).to have_content 'This might interest you'

      # The announcement has been sent out with adjusted subject and content.
      expect(
        send_announcement.with(
          body: hash_including(
            'recipients' => [
              "urn:x-xikolo:account:user:#{user_id}",
              'urn:x-xikolo:account:group:some.group.1',
              'urn:x-xikolo:account:group:course.another-course.students',
              'urn:x-xikolo:account:group:course.some-course.students',
            ],
            'creator_id' => user_id,
            'test' => false,
            'consents' => %w[treatment.marketing],
            'translations' => {
              'en' => {
                'subject' => 'News: This might interest you',
                'content' => 'Dear users, please check it out!',
              },
            }
          )
        )
      ).to have_been_requested
    end
  end

  it 'publishes a test email announcement' do
    visit "/admin/announcements/#{announcement_id}/email/new"

    within_fieldset('English') do
      expect(page).to have_field('Subject', with: 'This might interest you')
      expect(page).to have_markdown_editor('Content', with: 'Check it out!')
    end

    tom_select 'Some User', from: 'Recipients', search: true
    find('label', text: 'Send as test email?').click

    send_announcement = Stub.request(:news, :post, "/announcements/#{announcement_id}/messages")
      .to_return(status: 201)

    click_link_or_button 'Send announcement email'

    # Since there is no flash message when a test announcement has been
    # sent out, we check that the announcement is visible on the page
    # (listed under "Draft").
    expect(page).to have_content 'This might interest you'

    expect(
      send_announcement.with(
        body: hash_including(
          'recipients' => ["urn:x-xikolo:account:user:#{user_id}"],
          'creator_id' => user_id,
          'test' => true,
          'translations' => {
            'en' => {
              'subject' => 'This might interest you',
              'content' => 'Check it out!',
            },
          }
        )
      )
    ).to have_been_requested
  end
end
