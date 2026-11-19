# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: If a section forum page gets locked', type: :system do
  let(:course) { create(:'course_service/course', :active, pinboard_enabled: true) }
  let!(:section) { create(:'course_service/section', course: course, title: 'Test Section') }
  let(:admin) { create(:'account_service/user') }
  let!(:topic) do
    create(
      :'pinboard_service/question',
      course_id: course.id,
      title: 'Section Topic',
      implicit_tags: [
        create(:'pinboard_service/implicit_tag', name: section.id, referenced_resource: 'Xikolo::Course::Section', course_id: course.id),
      ]
    )
  end
  let!(:answer) { create(:'pinboard_service/answer', question: topic, user_id: admin.id) }

  before do
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group: group)

    sign_in(user: admin)
    enroll_in(course)
  end

  it 'prevents posting new topics and shows locked message in section' do
    click_on 'Course Administration'
    click_on 'Structure & Content'

    click_on 'Action'
    click_on 'Edit'
    click_on 'Advanced settings'
    find('label', text: 'Close discussions?').click
    click_on 'Update Section'

    expect(page).to have_text("The section #{section.title} has been updated")

    click_on 'Go to course'
    click_on 'Discussion'

    find('select[name=pinboard_section]').select section.title

    expect(page).to have_no_text('Start a new topic')
    expect(page).to have_text("The discussions for the section \"#{section.title}\" are read-only")

    click_on 'Section Topic'

    expect(page).to have_no_text('Start a new topic')
    expect(page).to have_text("The discussions for the section \"#{section.title}\" are read-only")
    expect(page).to have_text(answer.text)
  end
end
