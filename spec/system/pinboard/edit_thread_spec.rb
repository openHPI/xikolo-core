# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Edit a topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course: course) }
  let(:student) { create(:'account_service/user') }
  let!(:topic) do
    create(
      :'pinboard_service/question',
      course_id: course.id,
      user_id: student.id,
      title: 'Original Topic Title',
      text: 'Original Topic Text',
      implicit_tags: [
        create(:'pinboard_service/implicit_tag', name: section.id, referenced_resource: 'Xikolo::Course::Section', course_id: course.id),
      ]
    )
  end

  before do
    sign_in(user: student)
    enroll_in(course)
    visit "/courses/#{course.course_code}/question/#{topic.id}"
  end

  it 'leaves the topic unchanged if updated without modifications' do
    find('.question-edit').click
    click_on 'Save changes'

    expect(page).to have_text('Original Topic Title')
    expect(page).to have_text(section.title)
  end

  it 'allows editing the title' do
    find('.question-edit').click

    fill_in 'xikolo_pinboard_question[title]', with: 'New Topic Title'
    click_on 'Save changes'

    expect(page).to have_text('New Topic Title')
    expect(page).to have_no_text('Original Topic Title')
  end

  it 'allows canceling the edit' do
    find('.question-edit').click

    expect(page).to have_css('.edit-post', visible: :visible)

    find('.cancel-post').click

    expect(page).to have_no_css('.edit-post', visible: :visible)
    expect(page).to have_text('Original Topic Title')
  end
end
