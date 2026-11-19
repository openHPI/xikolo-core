# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Subscribe to topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }
  let!(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: user.id) }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  it 'subscribes to a topic' do
    click_on 'Forum'
    click_on question.title

    click_on 'Follow topic'

    expect(page).to have_css 'span.fa-star.fa-solid'
    expect(page).to have_button 'Unfollow topic'

    subscription = PinboardService::Subscription.find_by(
      question_id: question.id,
      user_id: user.id
    )
    expect(subscription).to be_present
  end
end
