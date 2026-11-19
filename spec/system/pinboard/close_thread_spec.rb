# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Closing a topic in a forum', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course: course) }
  let(:user) { create(:'account_service/user') }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: user.id) }

  before do
    create(:'pinboard_service/answer', question: question, user_id: user.id)

    teacher = create(:'account_service/user')
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.teachers")
    create(:'account_service/membership', user: teacher, group:)

    visit '/'
    sign_in(user: teacher)
    enroll_in(course)
  end

  it 'closes a topic as teacher' do
    click_on 'Forum'
    click_on question.title

    expect(page).to have_text(question.title)
    expect(page).to have_text('Reply')
    expect(page).to have_text('Add comment')

    click_on 'Close'
    click_on 'Yes, sure'

    expect(page).to have_text('The entry was closed and is now read-only')
    expect(page).to have_no_text('Reply')
    expect(page).to have_no_text('Add comment')
    expect(page).to have_text('Reopen')
  end

  it 'reopens a previously closed topic as teacher' do
    question.update!(closed: true)

    click_on 'Forum'
    click_on question.title

    visit "/learn/#{course.course_code}/question/#{question.id}"

    expect(page).to have_text(question.title)
    expect(page).to have_text('The entry was closed and is now read-only')
    expect(page).to have_no_text('Reply')
    expect(page).to have_no_text('Add comment')
    expect(page).to have_text('Reopen')

    click_on 'Reopen'
    click_on 'Yes, sure'

    expect(page).to have_no_text('The entry was closed and is now read-only')
    expect(page).to have_text('Reply')
    expect(page).to have_text('Add comment')
    expect(page).to have_text('Close')
  end
end
