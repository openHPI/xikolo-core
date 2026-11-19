# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: List topics by tag', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }

  it 'lists topics by tag' do
    tag1 = create(:'pinboard_service/explicit_tag', course_id: course.id, name: 'Databases')
    tag2 = create(:'pinboard_service/explicit_tag', course_id: course.id, name: 'SQL')

    create(:'pinboard_service/question', course_id: course.id, title: 'Topic about DB', explicit_tags: [tag1])
    create(:'pinboard_service/question', course_id: course.id, title: 'Topic about SQL', explicit_tags: [tag2])
    create(:'pinboard_service/question', course_id: course.id, title: 'Topic about both', explicit_tags: [tag1, tag2])

    sign_in(user: student)
    enroll_in(course)
    click_on 'Forum'

    # Verify all three exist initially
    expect(page).to have_text('Topic about DB')
    expect(page).to have_text('Topic about SQL')
    expect(page).to have_text('Topic about both')

    # Click on the tag 'Databases'
    first('[data-tag-id]', text: 'Databases').click

    # Verify only topics with 'Databases' tag are shown
    expect(page).to have_text('Topic about DB')
    expect(page).to have_text('Topic about both')
    expect(page).to have_no_text('Topic about SQL')

    # All displayed topics should have the filtered tag
    expect(page.all(:css, '.pinboard-question-info-tags')).to all(have_text('Databases'))
  end
end
