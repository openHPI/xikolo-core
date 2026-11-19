# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Promote a user as a teacher', type: :system do
  let(:gdpr_admin) { create(:'account_service/user', :gdpr_admin) }
  let(:additional_user) { create(:'account_service/user', display_name: 'Jane Austen') }

  before do
    sign_in(user: gdpr_admin)
    visit user_path(additional_user)
  end

  context 'Successfully promote a teacher' do
    it 'promotes the user and configures their teacher information' do
      click_on 'Promote to teacher'

      fill_markdown_editor 'Bio (English)', with: 'Example blurb english'
      fill_markdown_editor 'Bio (German)', with: 'Example blurb deutsch'
      click_on 'Save information'

      expect(page).to have_text 'Teacher information has been successfully saved!'

      visit user_path(additional_user)

      expect(page).to have_link 'Show teacher information'
      click_on 'Show teacher information'

      expect(page).to have_text 'Example blurb english'
      expect(page).to have_text 'Example blurb deutsch'
    end
  end

  context 'Test fallback logic of teacher description' do
    let(:course) do
      create(:'course_service/course', title: 'Test Course', course_code: 'testcourse')
    end

    it 'shows the German description when only German is provided and language is English' do
      # 1. Promote to teacher with only German
      click_on 'Promote to teacher'
      fill_markdown_editor 'Bio (German)', with: 'Example blurb deutsch'
      click_on 'Save information'
      expect(page).to have_text 'Teacher information has been successfully saved!'

      # 2. Assign the additional user to the course as a teacher
      visit edit_course_path(course.course_code)
      tom_select additional_user.display_name, from: 'Teachers', search: true

      page.execute_script("document.querySelector('form').noValidate = true;")
      find('.btn-group input[type="submit"]').click
      expect(page).to have_text('The course has been updated.')

      # 3. Visit the course detail page in English
      visit course_path(course.course_code, locale: 'en')

      # Then I see the German description
      expect(page).to have_text 'Example blurb deutsch'
    end
  end
end
