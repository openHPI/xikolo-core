# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: List unread topics', type: :system do
  include ActiveJob::TestHelper

  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }
  let(:other_student) { create(:'account_service/user') }

  before do
    sign_in(user: student)
    enroll_in(course)
  end

  it 'reading a topic marks it read' do
    create(:'pinboard_service/question', course_id: course.id, user_id: other_student.id, title: 'Unread Topic')

    click_on 'Forum'

    expect(page).to have_css('.pinboard-question.unread', count: 1)

    perform_enqueued_jobs do
      click_on 'Unread Topic'
      expect(page).to have_link('All discussions')
      expect(page).to have_link('Unread Topic')
      wait_for_turbo_idle
    end

    click_on 'Forum'

    expect(page).to have_css('.pinboard-question')
    expect(page).to have_no_css('.pinboard-question.unread')

    using_session(:other) do
      yet_another_user = create(:'account_service/user')
      sign_in(user: yet_another_user)
      enroll_in(course)

      click_on 'Forum'

      expect(page).to have_css('.pinboard-question.unread', count: 1)
    end
  end

  it 'posting a topic marks it read for the author' do
    click_on 'Forum'

    click_on 'Start a new topic'
    fill_in 'Title', with: 'My New Topic'
    fill_markdown_editor 'Text', with: 'Body of the topic'

    perform_enqueued_jobs do
      click_on 'Post new topic'
      expect(page).to have_text('My New Topic')
      wait_for_turbo_idle
    end

    click_on 'Forum'

    expect(page).to have_text('My New Topic')
    expect(page).to have_css('.pinboard-question')
    expect(page).to have_no_css('.pinboard-question.unread')
  end

  it 'updating a read topic marks it unread' do
    topic = create(:'pinboard_service/question', course_id: course.id, user_id: other_student.id, title: 'Updated Topic')

    click_on 'Forum'

    expect(page).to have_css('.pinboard-question.unread', count: 1)

    perform_enqueued_jobs do
      click_on 'Updated Topic'
      expect(page).to have_link('All discussions')
      expect(page).to have_link('Updated Topic')
      wait_for_turbo_idle
    end

    visit "/courses/#{course.course_code}/pinboard"
    expect(page).to have_css('.pinboard-question')
    expect(page).to have_no_css('.pinboard-question.unread')

    create(:'pinboard_service/answer', question: topic, user_id: other_student.id, text: 'New Answer')

    click_on 'Forum'

    expect(page).to have_css('.pinboard-question.unread', count: 1)
  end
end
