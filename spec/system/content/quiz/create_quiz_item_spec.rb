# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Create quiz item', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:user) { create(:'account_service/user') }

  before do
    section
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group:)
    sign_in(user:)
  end

  it 'creates a main quiz with a question pool' do
    visit "/learn/#{course.course_code}/sections"
    click_on 'Add exam'

    fill_in 'Title', with: 'Question pool quiz'
    fill_in 'Course progression required', with: '75'
    fill_in 'Passing score', with: '50'
    fill_markdown_editor 'Instructions', with: 'Quiz instructions'

    click_on 'Create Item'

    expect(page).to have_text('Edit item "Question pool quiz"')
  end

  it 'creates a selftest quiz without instructions' do
    # The instructions field is hidden for selftests. A hidden `required`
    # control that cannot be focused blocks form submission in the browser,
    # so creating the item must still work without entering instructions.
    visit "/learn/#{course.course_code}/sections"
    click_on 'Add item'

    fill_in 'Title', with: 'Self test quiz'
    select 'Quiz', from: 'Type'
    select 'Self test', from: 'Exercise type'

    click_on 'Create Item'

    expect(page).to have_text('Edit item "Self test quiz"')
  end
end
