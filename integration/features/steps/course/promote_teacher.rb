# frozen_string_literal: true

module Steps
  module PromoteTeacher
    Given 'I am on his user detail page' do
      send 'When I open the users list'

      email = context.fetch(:additional_user).fetch('email')
      expect(email).to be_present

      tr = find :xpath, "//tr[td[contains(., '#{email}')]]"
      tr.click_on 'Details'
    end

    When 'I promote him to a teacher' do
      click_on 'Promote to teacher'
    end

    When 'I submit the teacher information' do
      fill_markdown_editor 'Bio (English)', with: 'Example blurb english'
      fill_markdown_editor 'Bio (German)', with: 'Example blurb deutsch'
      fill_markdown_editor 'Bio (French)', with: 'Example blurb francais'
      click_on 'Save information'

      expect(page).to have_content 'Teacher information has been successfully saved!'
    end

    When 'I only provide a German description' do
      fill_markdown_editor 'Bio (German)', with: 'Example blurb deutsch'
      click_on 'Save information'

      expect(page).to have_content 'Teacher information has been successfully saved!'
    end

    When 'I visit his user detail page' do
      send 'Given I am on his user detail page'
    end

    Then 'the user is a teacher' do
      expect(page).to have_link 'Show teacher information'
    end

    Then 'I see the German description' do
      expect(page).to have_content 'Example blurb deutsch'
    end

    Then 'the user has his teacher information configured' do
      click_on 'Show teacher information'

      expect(page).to have_content 'Example blurb english'
      expect(page).to have_content 'Example blurb deutsch'
      expect(page).to have_content 'Example blurb francais'
    end
  end
end

Gurke.configure do |c|
  c.include Steps::PromoteTeacher
end
