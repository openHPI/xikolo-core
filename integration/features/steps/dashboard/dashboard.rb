# frozen_string_literal: true

module Steps
  module Dashboard
    Then 'no documents should be listed' do
      expect(page).to have_content('There are no certificates available yet.')
    end

    Then 'a COP should be listed' do
      context.with :course do |course|
        expect(page).to have_content course.title, count: 1
        expect(page).to have_content 'Download Confirmation of Participation', count: 1
      end
    end

    Then 'I can download the COP' do
      url = page.find_link('Download Confirmation of Participation')['href']
      expect(download_file(url)).to include 'rendered'
    end

    Then 'all course can be marked as completed' do
      context.with :course, :archived_course do |course, archived_course|
        within('.course-card', text: course.title) do
          find('[aria-label="More actions"]').click
          expect(page).to have_content 'Mark as completed'
        end

        within('.course-card', text: archived_course.title) do
          find('[aria-label="More actions"]').click
          expect(page).to have_content 'Mark as completed'
        end
      end
    end

    When 'I mark the archived course as completed' do
      context.with :archived_course do |course|
        within('.course-card', text: course.title) do
          find('[aria-label="More actions"]').click
          within('[data-behaviour="menu-dropdown"]') do
            click_on 'Mark as completed'
          end
        end
      end
    end

    Then 'I am asked to confirm completion' do
      expect(page).to have_content 'Are you sure?'
    end

    When 'I confirm completion of the course' do
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    Then 'the modal should close automatically' do
      expect(page).not_to have_selector '.util-modal__frame'
    end

    Then 'the archived course is listed as completed course' do
      context.with :archived_course do |course|
        within('.course-group', text: 'My completed courses') do
          expect(page).to have_content course.title
        end
      end
    end

    When 'I am on the admin dashboard' do
      visit '/admin/dashboard'
    end

    Then 'I see a sending state' do
      expect(page).to have_css '.announcement-state', count: 1
    end
  end
end

Gurke.configure {|c| c.include Steps::Dashboard }
