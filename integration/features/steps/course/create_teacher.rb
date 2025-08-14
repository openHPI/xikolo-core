# frozen_string_literal: true

module Steps
  module CreateTeacher
    When 'I create a new teacher' do
      click_on 'New teacher'
    end

    When 'I fill in a name' do
      fill_in 'Name', with: 'Example teacher name'
    end

    Then 'I see the new teacher' do
      expect(page).to have_content 'Example teacher name'
    end

    Then 'the teacher has his information configured' do
      Capybara.enable_aria_label = true
      click_on 'Example teacher name'

      expect(page).to have_content 'Example blurb english'
      expect(page).to have_content 'Example blurb deutsch'

      Capybara.enable_aria_label = false
    end
  end
end

Gurke.configure do |c|
  c.include Steps::CreateTeacher
end
