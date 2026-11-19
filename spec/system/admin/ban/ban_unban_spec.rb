# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Ban and Unban User', type: :system do
  let(:user) { create(:'account_service/user', :gdpr_admin) }
  let(:target_user) { create(:'account_service/user') }

  before do
    sign_in(user:)
  end

  it 'bans and unbans a user successfully' do
    visit "/users/#{target_user.id}"

    expect(page).to have_text('This account has been banned 0 times before.')

    click_on 'Ban user'
    click_on 'Yes, sure'

    expected_last_ban = I18n.l(target_user.reload.banned_at, format: :long_datetime_zone)

    expect(page).to have_text('The user was banned successfully.')
    expect(page).to have_text('This account has been banned 1 times before.')
    expect(page).to have_text("The last ban was on #{expected_last_ban}.")

    click_on 'Unban user'
    click_on 'Yes, sure'

    expect(page).to have_text('The user was unbanned successfully.')
    expect(page).to have_link('Ban user')
  end
end
