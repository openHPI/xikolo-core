# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Unsubscribe topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: user.id) }

  before do
    sign_in(user:)
    enroll_in(course)
    create(:'pinboard_service/subscription', question:, user_id: user.id)
  end

  it 'unsubscribes via forum topic' do
    click_on 'Forum'
    click_on question.title

    click_on 'Unfollow'

    expect(page).to have_css 'span.fa-star.fa-regular'
    expect(page).to have_button 'Follow topic'

    subscription = PinboardService::Subscription.find_by(
      question_id: question.id,
      user_id: user.id
    )
    expect(subscription).to be_nil
  end

  it 'unsubscribes via user profile' do
    visit '/preferences'

    within('.account-notifications__subscriptions') do
      expect(page).to have_text question.title

      find("a[href*='#{question.id}'][data-method='post']").click
    end

    expect(page).to have_no_text question.title

    subscription = PinboardService::Subscription.find_by(
      question_id: question.id,
      user_id: user.id
    )
    expect(subscription).to be_nil
  end
end
