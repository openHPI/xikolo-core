# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Banned user login', type: :system do
  let(:user) { create(:'account_service/user', :banned) }

  it 'shows a banned error message' do
    visit '/'

    click_on 'Log in'
    fill_in 'E-mail', with: user.primary_email.address
    fill_in 'Password', with: attributes_for(:'account_service/user').fetch(:password)

    within '#login-form' do
      click_on 'Log in'
    end

    expect(page).to have_text(I18n.t('flash.error.banned_user'))
  end
end
