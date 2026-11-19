# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Find user email address', type: :system do
  let(:additional_user) { create(:'account_service/user') }

  before do
    create(:'course_service/course', :active)
  end

  it 'shows the email address to an admin' do
    sign_in(user: create(:'account_service/user', :gdpr_admin))
    visit "/users/#{additional_user.id}"

    expect(page).to have_link(
      additional_user.email,
      href: "mailto:#{additional_user.email}",
      count: 1
    )
  end

  it 'does not show the email address to a normal user' do
    sign_in

    visit "/users/#{additional_user.id}"
    expect(page).to have_text(additional_user.name)
    expect(page).to have_no_link(additional_user.email)
  end
end
