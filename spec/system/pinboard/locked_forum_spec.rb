# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Cant see new topic button in locked forum', type: :system do
  let(:course) { create(:'course_service/course', :active, forum_is_locked: true) }
  let(:student) { create(:'account_service/user') }

  before do
    sign_in(user: student)
    enroll_in(course)
  end

  it 'does not show the new topic button and shows locked message' do
    click_on 'Forum'
    find('.pinboard-topics')

    expect(page).to have_no_button('Start a new topic')
    expect(page).to have_text('The discussions for this course are read-only')
  end
end
