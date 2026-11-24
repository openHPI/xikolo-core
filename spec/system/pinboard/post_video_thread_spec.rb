# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Post a video topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:video) { create(:video) }
  let(:item) { create(:'course_service/item', section:, content: video) }
  let(:user) { create(:'account_service/user') }

  before do
    item
    sign_in(user:)
    enroll_in(course)
  end

  it 'posts a topic in a video context' do
    within('[data-testid="course-details-card"]') do
      click_on 'Continue course'
    end

    find_by_id('show-topic-form').click

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor 'Text', with: 'To Be, Or *Not* To Be'

    click_on 'Submit'

    expect(page).to have_text 'An important Question'
  end

  it 'belongs to the correct section and item' do
    create(:'pinboard_service/question',
      course_id: course.id,
      user_id: user.id,
      title: 'An important Question',
      text: 'I have no idea what to ask.',
      item_id: item.id)

    within('[data-testid="course-details-card"]') do
      click_on 'Continue course'
    end

    expect(page).to have_text section.title
    expect(page).to have_text item.title
  end

  it 'shows existing video topics but no new topic form when course forum is locked' do
    create(:'pinboard_service/question',
      course_id: course.id,
      user_id: user.id,
      title: 'Existing Topic',
      text: 'Body',
      item_id: item.id)
    course.update_column(:forum_is_locked, true)

    within('[data-testid="course-details-card"]') do
      click_on 'Continue course'
    end

    expect(page).to have_text 'Existing Topic'
    expect(page).to have_no_css('#show-topic-form')
  end

  it 'shows existing video topics but no new topic form when section forum is locked' do
    create(:'pinboard_service/question',
      course_id: course.id,
      user_id: user.id,
      title: 'Existing Topic',
      text: 'Body',
      item_id: item.id)
    section.update_column(:pinboard_closed, true)

    visit "/learn/#{course.course_code}/items/#{item.id}"

    expect(page).to have_text 'Existing Topic'
    expect(page).to have_no_css('#show-topic-form')
  end

  it 'edits a topic in a video context and keeps section and item assignment' do
    create(:'pinboard_service/question',
      course_id: course.id,
      user_id: user.id,
      title: 'An important Question',
      text: 'I have no idea what to ask.',
      item_id: item.id)

    visit "/learn/#{course.course_code}/items/#{item.id}"

    click_on 'View or reply'
    find('.question-edit').click

    fill_in 'xikolo_pinboard_question[title]', with: 'Edited Question'
    click_on 'Save changes'

    expect(page).to have_text 'Edited Question'
    expect(page).to have_text section.title
    expect(page).to have_text item.title
  end
end
