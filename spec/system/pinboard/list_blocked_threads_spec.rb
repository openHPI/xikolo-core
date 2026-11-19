# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: List blocked topics', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }
  let(:admin) do
    user = create(:'account_service/user')
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group:)
    user
  end

  it 'does not show a blocked topic to a regular user' do
    create(:'pinboard_service/question', course_id: course.id, title: 'Blocked Topic', workflow_state: 'blocked')

    sign_in(user: student)
    enroll_in(course)
    click_on('Forum')
    find('.pinboard-topics')

    expect(page).to have_no_text('Blocked Topic')
  end

  it 'shows a blocked topic to a course admin' do
    create(:'pinboard_service/question', course_id: course.id, title: 'Blocked Topic', workflow_state: 'blocked')

    sign_in(user: admin)
    visit course_path(course)
    click_on('Forum')
    find('.pinboard-topics')

    within('.question-title') do
      expect(page).to have_text('Blocked Topic')
      expect(page).to have_text('[Blocked]')
    end
  end

  it 'shows a blocked and reviewed topic to a regular user' do
    create(:'pinboard_service/question', course_id: course.id, title: 'Reviewed Topic', workflow_state: 'reviewed')

    sign_in(user: student)
    enroll_in(course)
    click_on('Forum')
    find('.pinboard-topics')

    expect(page).to have_text('Reviewed Topic')
  end
end
