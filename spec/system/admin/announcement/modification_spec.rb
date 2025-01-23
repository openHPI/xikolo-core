# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Modify Announcement', type: :system do
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
      publication_channels: {email: nil},
      author_id: user_id,
      created_at: 1.day.ago,
      self_url: "/announcements/#{announcement_id}",
    }
  end

  before do
    stub_user id: user_id,
      permissions: %w[news.announcement.create news.announcement.update],
      features: {'admin_announcements' => 'true'}
    Stub.service(:news, build(:'news:root'))

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)

    Stub.request(:news, :get, "/announcements/#{announcement_id}")
      .and_return Stub.json(announcement)
    Stub.request(:news, :get, '/announcements')
      .and_return Stub.json([announcement])
  end

  it 'prefills the form and updates the announcement' do
    visit "/admin/announcements/#{announcement_id}/edit"

    within_fieldset('English') do
      expect(page).to have_field('Subject', with: 'This might interest you')
      expect(page).to have_markdown_editor('Content', with: 'Check it out!')
    end

    update_announcement = Stub.request(:news, :patch, "/announcements/#{announcement_id}")
      .to_return(status: 201)

    click_link_or_button 'Update announcement'

    # Since there is no flash message when an announcement has been
    # updated, we check that the announcement is visible on the page
    # (listed under "Draft").
    expect(page).to have_content 'This might interest you'

    expect(
      update_announcement.with(
        body: hash_including(
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
