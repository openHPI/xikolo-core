# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Forum overview statistics', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }
  let!(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: user.id) }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  it 'shows zero reply and vote counts initially' do
    click_on 'Forum'

    within '.question-shortinfo.views' do
      expect(page).to have_text '0'
    end
    within '.question-shortinfo.answers' do
      expect(page).to have_text '0'
    end
    within '.votes' do
      expect(page).to have_text '0'
    end
  end

  it 'shows two replies after answering and commenting' do
    create(:'pinboard_service/answer', question:, user_id: create(:'account_service/user').id)
    create(:'pinboard_service/comment',
      commentable: question,
      commentable_type: 'PinboardService::Question',
      user_id: create(:'account_service/user').id)

    click_on 'Forum'

    within '.question-shortinfo.answers' do
      expect(page).to have_text '2'
    end
  end

  it 'shows vote count after voting' do
    create(:'pinboard_service/vote', votable: question, value: -1)
    create(:'pinboard_service/vote', votable: question, value: 1)
    create(:'pinboard_service/vote', votable: question, value: 1)

    click_on 'Forum'
    click_on question.title

    within '.votes' do
      expect(page).to have_text '1'
    end
  end
end
