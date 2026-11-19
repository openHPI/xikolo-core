# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Mark a solution as working', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:author) { create(:'account_service/user') }
  let(:admin) { create(:'account_service/user') }
  let(:other_user) { create(:'account_service/user') }
  let!(:topic) { create(:'pinboard_service/question', course_id: course.id, user_id: author.id) }

  before do
    create(:'pinboard_service/answer', question: topic, user_id: other_user.id, text: 'I think I know the answer: 42!')
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group: group)
  end

  it 'allows the owner of the topic to mark a solution as working' do
    sign_in(user: author)
    enroll_in(course)

    click_on 'Forum'
    click_on topic.title

    find('.accept').click

    expect(page).to have_css('.accepted', text: 'I think I know the answer: 42!')
  end

  it 'allows a course admin to mark a solution as working' do
    sign_in(user: admin)

    visit course_path(course)

    click_on 'Forum'
    click_on topic.title

    find('.accept').click

    expect(page).to have_css('.accepted', text: 'I think I know the answer: 42!')
  end
end
