# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Announcement', type: :system do
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }

  before do
    stub_user id: user_id,
      permissions: %w[news.announcement.create],
      features: {'admin_announcements' => 'true'}

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)

    Stub.request(:news, :get, '/announcements')
      .and_return Stub.json([])
  end

  it 'announcement is created' do
    visit '/admin/announcements/new'

    within_fieldset('English') do
      fill_in 'Subject', with: 'This might interest you'
      fill_markdown_editor 'Content', with: 'Check it out!'
    end

    create_announcement = Stub.request(:news, :post, '/announcements').to_return(status: 201)

    click_link_or_button 'Create announcement'

    # There is no stub for actual content after creation, so the page
    # stays empty even after "an announcement has been created".
    # Nevertheless, we must wait for the page to be there again.
    #
    # Otherwise the test would immediately continue checking the stub,
    # even if the actual request is still processed and might not have
    # called the stub yet.
    expect(page).to have_content 'There are currently no announcement drafts.'

    expect(
      create_announcement.with(
        body: hash_including(
          'author_id' => user_id,
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
