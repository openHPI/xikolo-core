# frozen_string_literal: true

require 'spec_helper'

describe 'Invite only course', type: :system do
  let(:course) { create(:'course_service/course', :active, invite_only: true) }
  let(:user) { create(:'account_service/user') }

  before do
    course
  end

  it 'does not allow a user to enroll themselves' do
    sign_in(user: user)

    # Check course list
    visit courses_path

    expect(page).to have_link(course.title, href: course_path(course.course_code))
    expect(page).to have_no_button('Enroll')
    expect(page).to have_no_link('Enroll')

    # Check course detail page
    within('.course-card', text: course.title) { click_on course.title }

    within('header') { expect(page).to have_css('a[aria-current="page"]', text: 'Details') }
    expect(page).to have_no_button('Enroll me now')
    expect(page).to have_no_link('Enroll me now')
    expect(page).to have_no_link('Enroll me for this course')
    expect(page).to have_no_link('Enroll for the course')
  end

  describe 'manual enrollment' do
    let(:admin) { create(:'account_service/user', :admin) }
    let(:additional_user) { create(:'account_service/user', full_name: 'Jane Doe', display_name: 'Jane') }

    before do
      additional_user
      role = create(:'account_service/role', permissions: ['account.user.find'])
      create(:'account_service/grant', principal: admin, role: role, context: AccountService::Context.root)

      sign_in(user: admin)
    end

    it 'allows course admin to enroll a user manually' do
      visit course_enrollments_path(course)

      tom_select additional_user.display_name, from: 'Search for user', search: true
      click_on 'Enroll user'

      expect(page).to have_text('User has been enrolled successfully.')
      expect(page).to have_text(additional_user.full_name)
      expect(page).to have_text(additional_user.email)
    end
  end
end
