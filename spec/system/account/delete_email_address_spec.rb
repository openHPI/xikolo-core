# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Delete email address', type: :system do
  let(:user) { create(:'account_service/user') }

  before do
    create(:'account_service/email', user: user, address: 'secondary@example.com', confirmed: true)
    sign_in(user: user)
  end

  it 'deletes secondary email' do
    click_on 'Profile'
    click_on 'Edit'
    click_on 'Edit my e-mail'

    wait_for_turbo_idle

    click_on 'Delete'

    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    expect(page).to have_text('Your secondary e-mail has successfully been deleted.')
    expect(page).to have_text('My profile')
  end
end
