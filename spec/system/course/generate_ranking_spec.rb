# frozen_string_literal: true

require 'spec_helper'

describe 'Administrator generates course ranking', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }

  before do
    create_list(:'account_service/user', 3)
    sign_in(user:)
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group: group)
  end

  it 'generates the course ranking' do
    visit edit_course_path(course)

    click_on 'Generate Ranking'

    expect(page).to have_text('The generate ranking request has been sent')
  end
end
