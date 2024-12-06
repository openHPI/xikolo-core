# frozen_string_literal: true

module Steps
  module CourseSection
    def create_section(course = context.fetch(:course))
      data = {
        title: 'A very important section!',
        description: 'I have no clue what the content of this section is',
        published: true,
        course_id: course['id'],
      }

      data.compact!

      Server[:course].api.rel(:sections).post(data).value!
    end

    def lock_section_forum(section)
      Server[:course].api.rel(:section).patch({pinboard_closed: true},
        {id: section.id}).value!
    end

    Given 'the section forum is locked' do
      context.with :section do |section|
        lock_section_forum section
      end
    end

    Given 'an active section was created' do
      context.assign :section, create_section
    end

    Given 'an active section was created for an archived course' do
      context.assign :section, create_section(context.fetch(:archived_course))
    end

    When 'I add a section' do
      click_on 'Add section'
    end

    When 'I fill in the section information' do
      fill_in 'Title', with: 'Week 1'
      fill_in 'Description', with: 'In the first week we introduce you to the topic'
      # Tab outside date picker, otherwise the "Advanced settings" button is obscured
      fill_in('Start date', with: 2.days.ago.utc.strftime('%Y-%m-%dT%H:%M:%SZ')).send_keys(:tab)
      click_on 'Advanced settings'
      fill_in 'End date', with: 2.days.from_now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    end

    When 'I save the section' do
      click_on 'Create Section'
    end

    When 'I mark the section as public' do
      page.find('label', text: 'Published').click
    end

    When 'I mark the section forum as closed' do
      click_on 'Action'
      click_on 'Edit'
      click_on 'Advanced settings'
      page.find('label', text: 'Close discussions?').click
      click_on 'Update Section'
    end

    When 'I edit the sections settings' do
      click_on 'Action'
      click_on 'Edit'
      fill_in 'Title', with: 'Edited Title'
      fill_in 'Description', with: 'Edited Description'
      click_on 'Update Section'
    end

    Then 'the section should be listed' do
      expect(page).to have_content 'Week 1'
      expect(page).to have_content 'In the first week we introduce you to the topic'
    end

    Then 'the section should not be published' do
      expect(page).to have_content 'Is not published'
      expect(page).to_not have_selector 'li.section.available'
    end

    Then 'the section should be published' do
      expect(page).to have_content 'Is published'
      expect(page).to have_selector 'li.section.available'
    end

    Then 'the edited section should be listed' do
      expect(page).to have_content 'Edited Title'
      expect(page).to have_content 'Edited Description'
    end

    Then 'I should get visual feedback that the action was successful' do
      expect(page).to have_notice 'The section Edited Title has been updated.'
    end
  end
end

Gurke.configure {|c| c.include Steps::CourseSection }
