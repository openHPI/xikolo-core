# frozen_string_literal: true

require 'spec_helper'

describe 'Show unpublished courses', type: :system do
  let!(:course) { create(:'course_service/course', published: false) }

  context 'as an administrator' do
    let(:admin) { create(:'account_service/user', :admin) }

    before do
      sign_in(user: admin)
    end

    it 'reads course information' do
      visit "/learn/#{course.course_code}"
      expect(page).to have_text(course.title)
    end

    it 'shows the course on the admin course list when filtered' do
      active_course = create(:'course_service/course', :active)
      visit '/admin/learn'

      expect(page).to have_text(active_course.title)
      expect(page).to have_text(course.title)

      select 'Preparation', from: 'Status'

      sleep 0.2 # JS has no event we can wait for. We need to wait
      # a little to make sure the new courses are loaded.

      expect(page).to have_text(course.title)
      expect(page).to have_no_text(active_course.title)
    end
  end

  context 'as a teacher' do
    let(:teacher) { create(:'account_service/user') }

    before do
      group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
      create('account_service/membership', user: teacher, group: group)

      sign_in(user: teacher)
    end

    it 'reads course information' do
      visit "/learn/#{course.course_code}"
      expect(page).to have_text(course.title)
    end
  end

  context 'as a confirmed user' do
    let(:user) { create(:'account_service/user') }

    before do
      sign_in(user: user)
    end

    it 'does not see the course listed' do
      visit courses_path

      expect(page).to have_text('Nothing here yet — check back soon!')
    end
  end
end
