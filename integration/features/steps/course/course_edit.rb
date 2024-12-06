# frozen_string_literal: true

module Steps
  module CourseEdit
    Given 'I am on the course edit page' do
      send :'Given I am on the course detail page'
      click_on 'Course Administration'
      click_on 'Settings'
    end

    Given 'I am on the course sections page' do
      send :'Given I am on the course detail page'
      click_on 'Course Administration'
      click_on 'Structure & Content'
    end

    Given 'I toggle the lock forum button' do
      page.find('label', text: 'Lock forum').click
    end

    Given 'I submit the course edit page' do
      click_on 'Update course'
    end

    When 'I am on the archived course edit page' do
      send :'Given I am on the archived course detail page'
      click_on 'Course Administration'
      click_on 'Settings'
    end

    When 'I generate the course ranking' do
      click_on 'Generate Ranking'
    end

    When 'I submit the course edit page' do
      click_on 'Update course'
    end

    When 'I delete the course' do
      click_on 'Delete course'
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I edit the current course' do
      click_on 'Course Administration'
      click_on 'Settings'
    end

    When 'I search for the additional user' do
      tom_select 'Jane', from: 'Search for user', search: true
    end

    When 'I enroll the user manually' do
      click_on 'Enroll user'
    end

    When 'I assign the additional user to the course as a teacher' do
      user = context.fetch :additional_user
      tom_select user[:name], from: 'Teachers'
      click_on 'Update course'
    end

    When 'I toggle the reactivation' do
      within_fieldset 'Certificates' do
        find('label', text: 'Reactivation').click
      end
    end

    Then 'I should see the course delete confirmation' do
      expect(page).to have_content('The course has been deleted.')
    end

    Then 'the course should not be listed on the admin courses page' do
      context.with :course do |course|
        expect(page).to have_content('All Courses') # /admin/courses page
        expect(page).to_not have_content course['course_code']
        expect(page).to_not have_content course['title']
      end
    end

    Then 'the course ranking is being generated' do
      wait_for_ajax
      expect(page).to have_content('The generate ranking request has been sent')
    end

    Then 'the user should be enrolled in the course' do
      expect(page).to have_content('User has been enrolled successfully.')
      context.with :additional_user do |user|
        expect(page).to have_content user['full_name']
        expect(page).to have_content user['email']
      end
    end

    Then(/the group (.*) is selected/) do |group|
      expect(page).to have_select('course_groups', selected: group)
    end
  end
end

Gurke.configure do |c|
  c.include Steps::CourseEdit
end
