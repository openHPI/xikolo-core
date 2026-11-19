# frozen_string_literal: true

require 'spec_helper'

describe 'Add alternative sections to a course', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:admin) { create(:'account_service/user') }

  before do
    create(:'course_service/section', course: course, title: 'Parent Section')
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group: group)

    sign_in(user: admin)
    visit "/learn/#{course.course_code}/sections"
  end

  it 'successfully adding an alternative section' do
    click_on 'Add alternative section'

    fill_in 'Title', with: 'Alternative 1'
    fill_in 'Description', with: 'This is the first alternative you can choose'

    click_on 'Create Section'

    expect(page).to have_current_path("/learn/#{course.course_code}/sections")
    expect(page).to have_text('The section Alternative 1 has been updated.')
    expect(page).to have_text('Alternative 1')
    expect(page).to have_text('This is the first alternative you can choose')
  end
end
