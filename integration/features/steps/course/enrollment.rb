# frozen_string_literal: true

module Steps
  module Course
    module Enrollment
      Given 'I unenroll from the course' do
        send :'When I unenroll from the course'
      end

      When 'I enroll in the course' do
        # The click target could be invisible, but still accessible by
        # expanding a course card.
        find("[data-behavior='expandable-enabled']").hover
        click_on('Enroll')
      end

      When 'I unenroll from the course' do
        click_on('Un-enroll')
      end

      Then 'I am enrolled in the course' do
        expect(page).to have_link('Un-enroll')
        context.with :course do |_course|
          expect(page).to have_notice 'You have been enrolled successfully.'
        end
      end

      Then 'I am unenrolled from the course' do
        send :'Then I am on the dashboard page'
        expect(page).to_not have_selector '.course-card'
      end

      Then 'I see a confirmation of unenrollment' do
        expect(page).to have_content 'You have been unenrolled.'
      end

      Then 'I receive a course welcome mail' do
        visit_email_view
        expect(page).to have_content 'welcome'
      end

      Then(/^I should not see a button labeled "(.*)"$/) do |text|
        expect(page).to have_no_button text
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Course::Enrollment }
