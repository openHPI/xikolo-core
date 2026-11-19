# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Move a topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:teacher) { create(:'account_service/user') }
  let(:student) { create(:'account_service/user') }

  let!(:general_topic) do
    create(
      :'pinboard_service/question',
      course_id: course.id,
      user_id: student.id,
      title: 'General Topic'
    )
  end

  let!(:section_topic) do
    section = create(:'course_service/section', course: course, title: 'Test Section')
    create(
      :'pinboard_service/question',
      course_id: course.id,
      user_id: student.id,
      title: 'Section Topic',
      implicit_tags: [
        create(:'pinboard_service/implicit_tag', name: section.id, referenced_resource: 'Xikolo::Course::Section', course_id: course.id),
      ]
    )
  end

  before do
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.teachers")
    create(:'account_service/membership', user: teacher, group: group)

    sign_in(user: teacher)
    enroll_in(course)
  end

  it 'moves a topic to a section' do
    visit "/learn/#{course.course_code}/question/#{general_topic.id}"

    find('.question-edit').click

    expect(page).to have_select(
      'Move to',
      with_options: ['Test Section']
    )

    select 'Test Section', from: 'Move to'
    click_on 'Save changes'

    within '.pinboard-content-container .x-breadcrumbs' do
      expect(page).to have_text('Test Section')
    end
  end

  it 'moves a topic to Technical Issues' do
    visit "/learn/#{course.course_code}/question/#{general_topic.id}"

    find('.question-edit').click

    expect(page).to have_select(
      'Move to',
      with_options: ['Technical Issues']
    )

    select 'Technical Issues', from: 'Move to'
    click_on 'Save changes'

    within '.pinboard-content-container .x-breadcrumbs' do
      expect(page).to have_text('Technical Issues')
    end
  end

  it 'removes a topic from a section' do
    visit "/learn/#{course.course_code}/question/#{section_topic.id}"

    within '.pinboard-content-container .x-breadcrumbs' do
      expect(page).to have_text('Test Section')
    end

    find('.question-edit').click

    expect(page).to have_select(
      'Move to',
      with_options: ['General']
    )

    select 'General', from: 'Move to'
    click_on 'Save changes'

    within '.pinboard-content-container .x-breadcrumbs' do
      expect(page).to have_no_text('Test Section')
    end
  end

  it 'leaves a topic\'s section unchanged' do
    visit "/learn/#{course.course_code}/question/#{section_topic.id}"

    find('.question-edit').click

    expect(page).to have_button('Save changes')

    click_on 'Save changes'

    within '.pinboard-content-container .x-breadcrumbs' do
      expect(page).to have_text('Test Section')
    end
  end
end
