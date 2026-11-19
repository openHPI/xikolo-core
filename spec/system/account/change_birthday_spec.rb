# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Change birthday', type: :system do
  it 'changes the date of birth' do
    sign_in
    click_on 'Profile'
    click_on 'Edit'
    click_on 'Edit my profile information'

    date_input = find('input[name="xikolo_account_user[born_at]"]', visible: false)
    page.execute_script("arguments[0].value = '2000-08-31'", date_input)

    click_button 'Save'

    expect(page).to have_text('The profile has been updated')
    expect(page).to have_text('31.08.2000')
  end
end
