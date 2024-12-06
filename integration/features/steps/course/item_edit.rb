# frozen_string_literal: true

module Steps
  module CourseItemEdit
    When(/I specify that the item is of type "([\w\s]+)"/) do |type|
      select type, from: 'Type'
    end

    When 'I fill out the minimal information for a richtext item' do
      fill_in 'Title', with: 'New Richtext Item'
      fill_markdown_editor 'Markup', with: 'Text for the richtext item'
    end

    When 'I save the richtext item' do
      click_on 'Create Item'
    end

    Then 'the item should offer the settings for items of type "richtext"' do
      expect(page).to have_content 'Markup'
      expect(page).to have_content 'Drop files here or click to browse'
    end

    Then 'the new richtext should be listed' do
      expect(page).to have_content 'New Richtext Item'
    end
  end
end

Gurke.configure {|c| c.include Steps::CourseItemEdit }
