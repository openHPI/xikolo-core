# frozen_string_literal: true

require 'spec_helper'

describe 'Assign users to special groups', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:admin) { create(:'account_service/user') }
  let!(:teacher_group_members) { create_list(:'account_service/user', 3) }
  let!(:additional_user) { create(:'account_service/user', full_name: 'Jane Austen') }

  before do
    # Setup course admin
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group: group)

    # Add teacher group members to the course teachers group
    teachers_group = AccountService::Group.find_by!(name: "course.#{course.course_code}.teachers")
    teacher_group_members.each do |teacher|
      create(:'account_service/membership', user: teacher, group: teachers_group)
    end

    sign_in(user: admin)
  end

  it 'views permissions' do
    visit course_permissions_path(course.course_code)

    within '#group-teachers' do
      teacher_group_members.each do |teacher|
        expect(page).to have_text(teacher.full_name)
        expect(page).to have_text(teacher.primary_email.address)
      end
    end

    within '#group-teachers' do
      expect(page).to have_text('Pinboard moderation')
    end

    within '#group-students' do
      expect(page).to have_text('Student: basic permissions')
    end
  end

  it 'removes a user from a special group' do
    visit course_permissions_path(course.course_code)

    within '#group-teachers' do
      teacher = find('td', text: teacher_group_members.first.full_name)
      teacher_row = teacher.ancestor('tr')

      within teacher_row do
        click_on('Remove')
      end
    end

    within '#group-teachers' do
      expect(page).to have_no_text(teacher_group_members.first.full_name)
      expect(page).to have_no_text(teacher_group_members.first.primary_email.address)
    end
  end

  it 'assigns a user to a special group' do
    visit course_permissions_path(course.course_code)

    email = additional_user.primary_email.address
    tom_select email[0..10], search: true, css: '#group-teachers'

    within '#group-teachers' do
      click_on 'Add user'
    end

    within '#group-teachers' do
      expect(page).to have_text(additional_user.full_name)
      expect(page).to have_text(additional_user.primary_email.address)
    end
  end
end
