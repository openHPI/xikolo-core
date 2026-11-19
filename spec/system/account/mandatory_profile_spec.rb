# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Mandatory profile', type: :system do
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user: user)
    click_on 'Profile'
    click_on 'Edit'
    click_on 'Edit my profile information'
  end

  it 'completes profiles' do
    fill_in 'Name', with: 'John Doe'
    fill_in 'Display name', with: 'John Doe'
    date_input = find('input[name="xikolo_account_user[born_at]"]', visible: false)
    page.execute_script("arguments[0].value = '2000-08-31'", date_input)
    select 'Teacher', from: 'Status'
    select 'Female', from: 'Gender'
    select 'Germany', from: 'Country', match: :first
    select 'Brandenburg', from: 'State'
    fill_in 'City', with: 'Potsdam'

    click_button 'Save'
    expect(page).to have_text 'The profile has been updated'

    visit '/dashboard'

    expect(page).to have_text('My upcoming learning opportunities')
  end
end
