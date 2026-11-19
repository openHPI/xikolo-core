# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Unblock a post', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:admin) { create(:'account_service/user') }
  let!(:question) do
    create(:'pinboard_service/question',
      course_id: course.id,
      workflow_state: 'blocked')
  end

  before do
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group:)
  end

  it 'unblocks a blocked topic' do
    sign_in(user: admin)

    visit course_path(course)

    click_on 'Forum'
    click_on question.title

    click_on 'review'

    expect(page).to have_no_text '[Blocked]'
    expect(page).to have_text question.title
  end
end
