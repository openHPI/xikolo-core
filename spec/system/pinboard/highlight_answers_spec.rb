# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Highlight unread answers', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }
  let(:other_student) { create(:'account_service/user') }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: other_student.id, title: 'Highlight Topic', text: 'Topic Text') }

  before do
    sign_in(user: student)
    enroll_in(course)
  end

  it 'highlights new answers to a topic' do
    create(:'pinboard_service/answer', question: question, user_id: other_student.id, text: 'First answer')

    perform_enqueued_jobs do
      visit "/learn/#{course.course_code}/question/#{question.id}"
      expect(page).to have_text('First answer')
    end

    create(:'pinboard_service/answer', question: question, user_id: other_student.id, text: 'Another answer',
      updated_at: 10.seconds.from_now)

    perform_enqueued_jobs do
      visit "/learn/#{course.course_code}/question/#{question.id}"
      expect(page).to have_css('.qa-answer', count: 2)
    end

    expect(find('.qa-answer', text: /First answer/)).not_to match_css('.unread')
    expect(find('.qa-answer', text: /Another answer/)).to match_css('.unread')
  end

  it 'highlights new comments to a topic' do
    create(:'pinboard_service/comment', commentable: question, user_id: other_student.id, text: 'First comment')

    perform_enqueued_jobs do
      visit "/learn/#{course.course_code}/question/#{question.id}"
      expect(page).to have_text('First comment')
    end

    create(:'pinboard_service/comment', commentable: question, user_id: other_student.id, text: 'Another comment',
      updated_at: 1.minute.from_now)

    perform_enqueued_jobs do
      visit "/learn/#{course.course_code}/question/#{question.id}"
      expect(page).to have_css('.comment-post', count: 2)
    end

    expect(find('.comment-post', text: /First comment/)).not_to match_css('.unread')

    expect(find('.comment-post', text: /Another comment/)).to match_css('.unread')
  end

  it 'highlights new comments to an answer' do
    answer = create(:'pinboard_service/answer', question: question, user_id: other_student.id, text: 'First answer')

    create(:'pinboard_service/comment', commentable: answer, user_id: other_student.id, text: 'First comment')

    perform_enqueued_jobs do
      visit "/learn/#{course.course_code}/question/#{question.id}"
      expect(page).to have_text('First comment')
    end

    create(:'pinboard_service/comment', commentable: answer, user_id: other_student.id, text: 'Another comment',
      updated_at: 1.minute.from_now)

    perform_enqueued_jobs do
      visit "/learn/#{course.course_code}/question/#{question.id}"
      expect(page).to have_css('.comment-post', count: 2)
    end

    expect(find('.comment-post', text: /First comment/)).not_to match_css('.unread')

    expect(find('.comment-post', text: /Another comment/)).to match_css('.unread')
  end
end
