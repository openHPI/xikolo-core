# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Delete Short', type: :system do
  let(:short) { create(:'course_service/short') }

  before do
    short
    sign_in(user: create(:'account_service/user', :admin))
    click_on('Administration')
    click_on('Shorts')
  end

  it 'allows a global course manager to remove a short' do
    expect(page).to have_text 'Short EN'
    click_link_or_button 'Delete'

    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    expect(page).to have_text('The short has been deleted.')
    expect(page).to have_current_path(admin_shorts_path)
    expect(page).to have_no_text('Short EN')
  end
end
