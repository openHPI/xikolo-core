# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Masquerade as other user', type: :system do
  let(:admin) { create(:'account_service/user', :gdpr_admin, display_name: 'GDPR Admin') }
  let(:additional_user) { create(:'account_service/user', display_name: 'Jane Austen') }

  it 'masquerades and demasquerades' do
    sign_in(user: admin)

    visit '/'
    click_on 'Administration'
    click_on 'Users'

    fill_in 'Search', with: additional_user.primary_email.address
    find_field('Search').send_keys(:return)

    click_on 'Details'
    click_on 'Masquerade as user'

    expect(page).to have_text('My upcoming learning opportunities')
    expect(page).to have_link('DEMASQ')
    expect(page).to have_css("[title='#{additional_user.name}']")

    click_on 'DEMASQ'

    expect(page).to have_no_link('DEMASQ')
  end
end
