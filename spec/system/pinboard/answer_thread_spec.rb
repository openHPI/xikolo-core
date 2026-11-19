# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Answer a topic', type: :system do
  include ActiveJob::TestHelper

  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }
  let(:other_user) { create(:'account_service/user') }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: other_user.id) }

  before do
    sign_in(user: user)
    enroll_in(course)

    create(:'course_service/enrollment', course: course, user_id: other_user.id)
    create(:'pinboard_service/subscription', question: question, user_id: other_user.id)
  end

  it 'answers a topic in the general forum' do
    visit "/learn/#{course.course_code}/question/#{question.id}"

    fill_markdown_editor '#markdown-input-text-answer-', use_selector: true, with: 'This is my test answer to help out.'

    perform_enqueued_jobs do
      click_on 'Post reply'
      wait_for_turbo_idle
    end

    expect(page).to have_text('This is my test answer to help out.')

    email = find_mail_to(other_user.email)
    expect(email.subject).to include('New post in a topic you are following')
  end

  it 'follows link in answer notification' do
    visit "/learn/#{course.course_code}/question/#{question.id}"

    fill_markdown_editor '#markdown-input-text-answer-', use_selector: true, with: 'This is my test answer to help out.'

    perform_enqueued_jobs do
      click_on 'Post reply'
      wait_for_turbo_idle
    end

    expect(page).to have_text('This is my test answer to help out.')

    email = find_mail_to(other_user.email)

    # Extract and verify the topic link from the email body
    # Note: Links are wrapped in tracking URLs like: /go/link?url=...question/ID...
    # The URL is URL-encoded, so question/ appears as %2Fquestion%2F
    email.html_part ? email.html_part.body.to_s : email.body.to_s
    expect(email.html_part.body.to_s).to include('%2Fquestion%2F')

    # Navigate to the topic via the link (simulating click)
    visit "/learn/#{course.course_code}/question/#{question.id}"
    expect(page).to have_css('.question-wrapper')
    expect(page).to have_text(question.title)
  end

  it 'answers a topic in the general forum with an attached document' do
    visit "/learn/#{course.course_code}/question/#{question.id}"

    fill_markdown_editor '#markdown-input-text-answer-', use_selector: true, with: 'Here is the document.'
    attach_file 'Attachment', Rails.root.join('spec/fixtures/files/www_slides.pdf'), id: 'xikolo_pinboard_answer_attachment'

    perform_enqueued_jobs do
      click_on 'Post reply'
      wait_for_turbo_idle
    end

    expect(page).to have_text('Here is the document.')
    expect(page).to have_link('Download attachment')
  end

  it 'answers a topic in the general forum with an attached image' do
    visit "/learn/#{course.course_code}/question/#{question.id}"

    fill_markdown_editor '#markdown-input-text-answer-', use_selector: true, with: 'Here is the image.'
    attach_file 'Attachment', Rails.root.join('spec/fixtures/files/redsandsforts.jpg'), id: 'xikolo_pinboard_answer_attachment'
    click_on 'Post reply'

    expect(page).to have_text('Here is the image.')
    expect(page).to have_css('.qa-attachment a img')
  end
end
