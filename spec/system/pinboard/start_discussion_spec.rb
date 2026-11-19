# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Start a topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  it 'starts a topic in the general course context' do
    click_on 'Forum'

    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    click_on 'Post new topic'

    expect(page).to have_link 'An important Question'
  end

  it 'starts a topic in a section forum' do
    section = create(:'course_service/section', course:)

    click_on 'Forum'

    find('select[name=pinboard_section]').select section.title

    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    click_on 'Post new topic'

    expect(page).to have_current_path("/learn/#{course.course_code}/sections/#{short_uuid(section.id)}/pinboard")
    expect(page).to have_link 'An important Question'
  end
end
