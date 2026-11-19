# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Commenting an answer in a topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }
  let(:other_student) { create(:'account_service/user') }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: other_student.id) }
  let(:subscriber_a) { create(:'account_service/user') }
  let(:subscriber_b) { create(:'account_service/user') }

  before do
    create(:'course_service/enrollment', course: course, user_id: other_student.id)
    create(:'pinboard_service/subscription', question: question, user_id: other_student.id)
    create(:'pinboard_service/subscription', question: question, user_id: subscriber_a.id)
    create(:'pinboard_service/subscription', question: question, user_id: subscriber_b.id)
    create(:'pinboard_service/answer', question:, user_id: other_student.id)

    visit '/'
    sign_in(user: student)
    enroll_in(course)
    click_on 'Forum'
    click_on question.title
  end

  it 'comments an answer in a forum' do
    # The question is also in a .qa-box, so we target the last one (the answer)
    all('.qa-box').last.click_on 'Add comment'

    fill_markdown_editor "[name='xikolo_pinboard_comment[text]']", use_selector: true, with: 'Good question'
    click_on 'Send comment'

    expect(page).to have_text('Good question')
  end

  it 'sends a notification email about comment' do
    all('.qa-box').last.click_on 'Add comment'

    fill_markdown_editor "[name='xikolo_pinboard_comment[text]']", use_selector: true, with: 'Good question'

    perform_enqueued_jobs do
      click_on 'Send comment'
      expect(page).to have_text('Good question')
      sleep 2 # No visual confirmation of processing. We need to wait.
    end

    # Check that every subscriber received a comment notification email
    [subscriber_a, subscriber_b].each do |subscriber|
      email = find_mail_to(subscriber.email)
      expect(email.subject).to include('New post in a topic you are following')

      body = email.html_part.body.to_s
      expect(body).to include('posted in a topic you are following')
    end

    # Verify the email contains a link to the topic, then visit it
    # (like the original feature's "I click on the topic link" step)
    email = find_mail_to(subscriber_a.email)
    body = email.html_part.body.to_s
    expect(body).to include("learn%2F#{course.course_code}%2Fquestion%2F#{question.id}")

    topic_path = "/learn/#{course.course_code}/question/#{question.id}"
    visit topic_path
    expect(page).to have_current_path(topic_path, ignore_query: true)
    expect(page).to have_css('.question-wrapper')
  end
end
