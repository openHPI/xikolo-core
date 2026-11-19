# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Confirmation', type: :system do
  let(:user) { create(:'account_service/user', :unconfirmed) }

  it 'requests a new confirmation email' do
    visit '/'

    click_on 'Log in'
    fill_in 'E-mail', with: user.primary_email.address
    fill_in 'Password', with: attributes_for(:'account_service/user').fetch(:password)

    within '#login-form' do
      click_on 'Log in'
    end

    expect(page).to have_text 'This e-mail address has not been confirmed yet.'
    click_on 'here'
    expect(page).to have_text 'We re-sent you a confirmation e-mail.'
  end
end
