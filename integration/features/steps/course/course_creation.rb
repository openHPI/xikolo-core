# frozen_string_literal: true

module Steps
  module CourseCreation
    Given 'I am on the course creation page' do
      send :'When I open the admin course list'
      click_on 'Create new course'
    end

    Given 'there is a configuration for access_groups' do
      set_xikolo_config('access_groups', 'company.partner': 'Partners')
    end

    Given 'a public channel was created' do
      context.assign :channel, create_channel(public: true)
    end

    When 'I filter for courses in preparation' do
      select('Preparation', from: 'Status')
    end

    When 'I fill in course title' do
      fill_in 'Title', with: 'Example Course Title'
    end

    When 'I fill in course code' do
      fill_in 'Course code', with: 'ECT01'
    end

    When 'I fill in course abstract' do
      fill_markdown_editor 'Abstract', with: 'The is a short(er) course abstract.'
    end

    When 'I fill in course description' do
      fill_markdown_editor 'Description', with: '**FETT**'
    end

    When 'I appoint some teachers' do
      # Does not work - tom_select/JavaScript

      # teachers = context.fetch :teachers
      # tom_select teachers[2]['name'], from: 'Teachers'
    end

    When 'I assign a channel' do
      tom_select 'Enterprise Channel', from: 'Channels', search: true
    end

    When 'I assign some categories' do
      # Does not work - tom_select/JavaScript
    end

    When 'I set a start date' do
      fill_in 'Start date (UTC)', with: 2.days.ago.iso8601
      find('body').click # loose focus to close time-picker
      # so other inputs can be opened
    end

    When 'I set an end date' do
      fill_in 'End date (UTC)', with: 19.days.from_now.iso8601
      find('body').click # loose focus to close time-picker
      # so other inputs can be opened
    end

    When 'I set the course status' do
      select 'Active', from: 'Status'
    end

    When 'I choose a language' do
      select 'English', from: 'Content language'
    end

    When 'I fill in the external course URL' do
      fill_in 'External course URL', with: 'https://mooc.house'
    end

    When 'I submit the course data' do
      click_on 'Create course'
      sleep 0.1
    end

    When 'I fill in the course data' do
      send :'When I fill in course title'
      send :'When I fill in course code'
      send :'When I fill in course abstract'
      send :'When I fill in course description'
      send :'When I appoint some teachers'
      send :'When I assign a channel'
      send :'When I assign some categories'
      send :'When I set a start date'
      send :'When I set an end date'
      send :'When I choose a language'
      send :'When I set the course status'
    end

    When 'I select the partner group restriction' do
      tom_select 'Partners', from: 'Restricted to groups'
    end

    Then 'I am on the new course page' do
      expect(page).to have_content 'Example Course Title'
      expect(page).to have_content 'The is a short(er) course abstract.'
      expect(page).to have_content 'FETT'

      # Rlly course page?
      expect(page).to have_link 'Enroll me for this course'
    end

    Then 'I am on the new external course page' do
      expect(page).to have_content 'Example Course Title'
      expect(page).to have_content 'The is a short(er) course abstract.'
      expect(page).to have_content 'FETT'

      expect(page).to have_link 'Go to external course'
    end

    Then 'I am not authorized' do
      expect(page).to have_content 'You do not have sufficient permissions for this action'
    end
  end
end

Gurke.configure do |c|
  c.include Steps::CourseCreation
end
