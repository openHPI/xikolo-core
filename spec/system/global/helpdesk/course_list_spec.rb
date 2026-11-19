# frozen_string_literal: true

require 'spec_helper'

describe 'Global: List courses in helpdesk', type: :system do
  let!(:course) { create(:'course_service/course', :active) }

  it 'lists public courses' do
    sign_in
    visit '/'
    find_by_id('helpdesk-button').click
    expect(page).to have_select 'Category', with_options: [course.title]
  end

  it 'lists public courses if not logged in' do
    visit '/'
    find_by_id('helpdesk-button').click
    expect(page).to have_select 'Category', with_options: [course.title]
  end

  it 'pre-selects course when in the course area' do
    sign_in
    click_on('Learn')
    click_on(course.title)
    wait_for_turbo_idle
    find_by_id('helpdesk-button').click
    expect(page).to have_select 'Category', selected: course.title
  end
end
