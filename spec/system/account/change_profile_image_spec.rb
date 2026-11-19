# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Change profile image', type: :system do
  before do
    sign_in
    visit '/dashboard/profile/edit_avatar'
  end

  it 'uploads a profile image' do
    attach_file 'xikolo_account_user_avatar', Rails.root.join('spec/fixtures/files/profile_image.jpg'), visible: false
    click_button 'Save'

    expect(page).to have_text('Your profile picture has been succesfully uploaded.')
    expect(page).to have_css("div[style*='avatar']")
  end
end
