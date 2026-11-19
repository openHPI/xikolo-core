# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Mark a solution in a section as working', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course: course, title: 'Test Section') }
  let(:author) { create(:'account_service/user') }
  let(:admin) { create(:'account_service/user') }
  let(:other_user) { create(:'account_service/user') }

  before do
    topic = create(
      :'pinboard_service/question',
      course_id: course.id,
      user_id: author.id,
      title: 'Section Topic',
      implicit_tags: [
        create(:'pinboard_service/implicit_tag', name: section.id, referenced_resource: 'Xikolo::Course::Section', course_id: course.id),
      ]
    )
    create(:'pinboard_service/answer', question: topic, user_id: other_user.id, text: 'I think I know the answer: 42!')
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group: group)
  end

  it 'allows the owner of the topic to mark a solution as working' do
    sign_in(user: author)
    enroll_in(course)

    click_on 'Forum'

    find('select[name=pinboard_section]').select section.title
    click_on 'Section Topic'

    find('.accept').click

    expect(page).to have_css('.accepted', text: 'I think I know the answer: 42!')
    expect(page).to have_text(section.title)
  end

  it 'allows a course admin to mark a solution as working' do
    sign_in(user: admin)

    visit course_path(course)

    click_on 'Forum'

    find('select[name=pinboard_section]').select section.title
    click_on 'Section Topic'

    find('.accept').click

    expect(page).to have_css('.accepted', text: 'I think I know the answer: 42!')
    expect(page).to have_text(section.title)
  end
end
