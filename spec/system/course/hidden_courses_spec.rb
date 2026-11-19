# frozen_string_literal: true

require 'spec_helper'

describe 'Hidden courses', type: :system do
  let!(:hidden_course) { create(:'course_service/course', :active, placement: [], title: 'A Hidden Course', course_code: 'hidden') }
  let(:user) { create(:'account_service/user') }
  let(:admin) { create(:'account_service/user', :admin) }

  it 'is hidden from user on public list' do
    sign_in(user: user)
    visit courses_path

    expect(page).to have_text('Nothing here yet — check back soon!')
  end

  it 'is shown to administrator on admin course list' do
    sign_in(user: admin)
    visit admin_courses_path

    expect(page).to have_text(hidden_course.title)
  end

  it 'is shown to enrolled user on their dashboard' do
    create(:'course_service/enrollment', user_id: user.id, course: hidden_course)

    sign_in(user: user)
    visit dashboard_path

    expect(page).to have_text(hidden_course.title)
  end
end
