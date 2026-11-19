# frozen_string_literal: true

require 'spec_helper'

describe 'Add a new section to a course', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }

  before do
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: user, group: group)

    sign_in(user: user)
    visit course_sections_path(course)
  end

  it 'successfully adds a section' do
    click_on 'Add section'

    fill_in 'Title', with: 'Week 1'
    fill_in 'Description', with: 'In the first week we introduce you to the topic'
    fill_in('Start date', with: 2.days.ago.utc.strftime('%Y-%m-%dT%H:%M:%SZ')).send_keys(:tab)
    click_on 'Advanced settings'
    fill_in 'End date', with: 2.days.from_now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

    click_on 'Create Section'

    expect(page).to have_current_path(course_sections_path(course))

    expect(page).to have_text('Week 1')
    expect(page).to have_text('In the first week we introduce you to the topic')

    expect(page).to have_text('Is not published')
    expect(page).to have_no_css('li.section.available')

    expect(page).to have_css('div[id^="edit_section_form_"][hidden]', visible: :all)
    expect(page).to have_no_css('div[id^="edit_section_form_"]:not([hidden])', visible: :all)
  end

  it 'successfully publishes a section' do
    click_on 'Add section'

    fill_in 'Title', with: 'Week 1'
    fill_in 'Description', with: 'In the first week we introduce you to the topic'
    fill_in('Start date', with: 2.days.ago.utc.strftime('%Y-%m-%dT%H:%M:%SZ')).send_keys(:tab)
    click_on 'Advanced settings'
    fill_in 'End date', with: 2.days.from_now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    find('body').click

    find('label', text: 'Published').click

    click_on 'Create Section'

    expect(page).to have_text('Is published')
    expect(page).to have_css('li.section.available')
  end
end
