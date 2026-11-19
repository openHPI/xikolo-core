# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Moderate topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:teacher) { create(:'account_service/user') }
  let(:topic) do
    create(:'pinboard_service/question',
      course_id: course.id,
      user_id: create(:'account_service/user').id,
      title: 'Original Title',
      text: 'Original text')
  end

  before do
    create(:'pinboard_service/comment',
      commentable: topic,
      commentable_type: 'PinboardService::Question',
      user_id: create(:'account_service/user').id,
      text: 'Original comment')

    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.teachers")
    create(:'account_service/membership', user: teacher, group: group)

    sign_in(user: teacher)
    enroll_in(course)
  end

  it 'edits a topic post' do
    visit "/courses/#{course.course_code}/question/#{topic.id}"

    find('.question-edit').click

    fill_in 'xikolo_pinboard_question[title]', with: 'Moderated Title'
    fill_markdown_editor('Text', with: 'Moderated text')

    click_on 'Save changes'

    expect(page).to have_text('Moderated Title')
    expect(page).to have_text('Moderated text')
  end

  it 'edits a comment' do
    visit "/courses/#{course.course_code}/question/#{topic.id}"

    find('.comment-edit').click

    fill_markdown_editor("#markdown-input-text-edit-comment-Question-#{topic.id}", use_selector: true, with: 'Moderated comment')

    within '.question-comments' do
      click_on 'Save changes'
    end

    expect(page).to have_text('Moderated comment')
    expect(page).to have_no_text('Original comment')
  end

  it 'cancels editing a comment' do
    visit "/courses/#{course.course_code}/question/#{topic.id}"

    within '.question-comments' do
      find('.comment-edit').click
      expect(page).to have_css('.edit-post', visible: :visible)

      find('.cancel-post').click
      expect(page).to have_no_css('.edit-post', visible: :visible)
    end

    expect(page).to have_text('Original comment')
  end

  it 'cancels editing an answer' do
    create(:'pinboard_service/answer', question: topic, user_id: create(:'account_service/user').id, text: 'Original answer')

    visit "/courses/#{course.course_code}/question/#{topic.id}"

    find('.answer-edit').click
    expect(page).to have_css('.edit-post', visible: :visible)

    within '.edit-post' do
      find('.cancel-post').click
    end
    expect(page).to have_no_css('.edit-post', visible: :visible)

    expect(page).to have_text('Original answer')
  end
end
