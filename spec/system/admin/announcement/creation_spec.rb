# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Announcement', type: :system do
  let(:user) { create(:'account_service/user', :admin) }

  before { sign_in(user:) }

  it 'announcement is created' do
    visit '/admin/announcements/new'

    within_fieldset('English') do
      fill_in 'Subject', with: 'This might interest you'
      fill_markdown_editor 'Content', with: 'Check it out!'
    end

    click_link_or_button 'Create announcement'

    expect(page).to have_text 'This might interest you'
  end
end
