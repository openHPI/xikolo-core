# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Modify Announcement', type: :system do
  let(:user) { create(:'account_service/user', :admin) }
  let(:announcement_id) { SecureRandom.uuid }
  let(:announcement_resource) do
    {
      id: announcement_id,
      title: 'This might interest you',
      translations: {'en' => {
        'subject' => 'This might interest you',
        'content' => 'Check it out!',
      }},
      publication_channels: {email: nil},
      author_id: user.id,
      created_at: 1.day.ago,
      self_url: "/news_service/announcements/#{announcement_id}",
    }
  end

  let(:announcement) do
    create(:'news_service/announcement', id: announcement_id, author_id: user.id)
  end

  before do
    announcement
    sign_in(user:)

    Stub.request(:news, :get, "/announcements/#{announcement_id}")
      .and_return Stub.json(announcement_resource)
    Stub.request(:news, :get, '/announcements')
      .and_return Stub.json([announcement_resource])
  end

  it 'prefills the form and updates the announcement' do
    visit "/admin/announcements/#{announcement_id}/edit"

    within_fieldset('English') do
      expect(page).to have_field('Subject', with: 'English Subject')
      expect(page).to have_markdown_editor('Content', with: 'Oh, you gonna like my news...')
    end

    update_announcement = Stub.request(:news, :patch, "/announcements/#{announcement_id}")
      .to_return(status: 201)

    click_link_or_button 'Update announcement'

    # Since there is no flash message when an announcement has been
    # updated, we check that the announcement is visible on the page
    # (listed under "Draft").
    expect(page).to have_text 'This might interest you'

    expect(
      update_announcement.with(
        body: hash_including(
          'translations' => {
            'en' => {
              'subject' => 'English Subject',
              'content' => 'Oh, you gonna like my news...',
            },
          }
        )
      )
    ).to have_been_requested
  end
end
