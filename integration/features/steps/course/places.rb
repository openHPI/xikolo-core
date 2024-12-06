# frozen_string_literal: true

module Steps
  module Course
    module Places
      Given 'I am on the course list' do
        visit '/courses'
        page.find('label', text: 'What would you like to learn?')
      end

      When 'I am on the course list' do
        send :'Given I am on the course list'
      end

      When 'I visit an invalid course page' do
        visit '/courses/nonexistingid'
      end

      Given 'I am on the course progress page' do
        course = context.fetch :course
        visit "/courses/#{course['course_code']}"
        click_on 'Progress'
      end

      Given 'I am on the course announcements page' do
        course = context.fetch :course
        visit "/courses/#{course['course_code']}"
        click_on 'Announcements'
      end

      Given 'I am on the section forum page' do
        send :'Given I am on the general forum'
        context.with :section do |section|
          find('select[name=pinboard_section]').select section['title']
        end
      end

      Given 'I am on the course detail page' do
        context.with :course do |course|
          visit "/courses/#{course['course_code']}"
        end
      end

      Given 'I am on the archived course detail page' do
        context.with :archived_course do |course|
          visit "/courses/#{course['course_code']}"
        end
      end

      When 'I am on the archived course detail page' do
        send :'Given I am on the archived course detail page'
      end

      When 'I am on the course detail page' do
        send :'Given I am on the course detail page'
      end

      When 'I open the admin course list' do
        visit '/'
        click_on 'Administration'
        within '[data-behaviour="menu-dropdown"]' do
          click_on 'Courses'
        end
      end

      Given 'I am on the teacher list' do
        visit '/teachers'
      end

      When 'I visit the teacher list' do
        send 'Given I am on the teacher list'
      end

      When 'I visit the course edit page' do
        send 'Given I am on the course edit page'
      end

      Given 'I am on the course sections page' do
        context.with :course do |course|
          visit "/courses/#{course['course_code']}/sections"
        end
      end

      Given 'I am on the item page' do
        context.with :course, :item do |course, item|
          visit "/courses/#{course['course_code']}/items/#{short_uuid item['id']}"
        end
      end

      When 'I return to the item page' do
        send :'Given I am on the item page'
      end

      Then 'I am on the item page' do
        context.with :course, :item do |course, item|
          expect(page).to have_current_path "/courses/#{course['course_code']}/items/#{short_uuid item['id']}"
        end
      end

      When 'I am on the item page of the archived course' do
        context.with :archived_course, :item do |course, item|
          visit "/courses/#{course['course_code']}/items/#{short_uuid item['id']}"
        end
      end

      Then 'I am redirected to the course detail page' do
        context.with :course do |course|
          expect(page).to have_current_path "/courses/#{course['course_code']}"
        end
      end

      Then 'I am redirected to a new submission for the quiz' do
        context.with :course, :item do |course, item|
          expect(page).to have_current_path(
            "/courses/#{course['course_code']}/items/#{short_uuid item['id']}/quiz_submission/new"
          )
        end
      end

      Given 'I am on the item edit page' do
        context.with :course, :section, :item do |course, section, item|
          visit "/courses/#{course['course_code']}/sections/#{section['id']}/items/#{item['id']}/edit"
        end
      end

      Then 'I am on the item edit page' do
        context.with :course, :section, :item do |course, section, item|
          expect(page).to have_current_path \
            "/courses/#{course['course_code']}/sections/#{section['id']}/items/#{item['id']}/edit"
        end
      end

      Given 'I am on the student enrollments page' do
        context.with :course do |course|
          visit "/courses/#{course['course_code']}/"
          click_on 'Course Administration'
          click_on 'Enrollments'
        end
      end

      Given 'I am on the course permissions page' do
        send :'Given I am on the course detail page'
        click_on 'Course Administration'
        # Expand Settings submenu
        find('a', text: 'Settings').hover
        find('[aria-controls^="item"]').click
        click_on 'Permissions'
      end

      When 'I am on the course permissions page' do
        send :'Given I am on the course permissions page'
      end

      When 'I select the course from the dashboard' do
        send :'Given I am on the dashboard page'
        click_on 'Resume'
      end

      Then 'I should be on the course sections page' do
        context.with :course do |course|
          expect(page).to have_current_path "/courses/#{course['course_code']}/sections"
        end
      end

      Then 'I am on the course detail page' do
        context.with :course do |course|
          expect(page).to have_current_path "/courses/#{course['course_code']}"
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Course::Places }
