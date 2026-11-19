# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: If a forum gets locked', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    create(:'pinboard_service/question', course_id: course.id, title: 'Sample Topic')

    sign_in(user: admin)
    enroll_in(course)
  end

  it 'prevents posting new topics and shows locked message' do
    click_on 'Course Administration'
    click_on 'Settings'

    find('label', text: 'Lock forum').click
    click_on 'Update course'

    expect(page).to have_text('The course has been updated')

    click_on 'Forum'

    expect(page).to have_text('The discussions for this course are read-only')
    expect(page).to have_no_text('Start a new topic')

    click_on 'Sample Topic'

    expect(page).to have_no_text('Start a new topic')
    expect(page).to have_text('The discussions for this course are read-only')
  end
end
