# frozen_string_literal: true

module Steps
  module Course
    When 'I navigate to the document creation page' do
      click_on 'Add new Document'
    end

    When 'I click on add a new localization' do
      click_on 'Add new Translation'
    end

    When 'I fill in the internal document title' do
      fill_in('document[title]', match: :first, with: 'Example Document Title')
    end

    When 'I fill in the internal document description' do
      fill_markdown_editor('Internal document description', with: 'Example Document Description')
    end

    When 'I add the localization language' do
      select 'Assamese', from: 'localization_language'
    end

    When 'I add the localization language later on' do
      select 'Bosnian', from: 'localization_language'
    end

    When 'I add the localization language later on in another language' do
      select 'Hindi', from: 'localization_language'
    end

    When 'I add a localization title' do
      fill_in('localization[title]', with: 'This is an example document title')
    end

    When 'I upload the localization file' do
      attach_file 'File (as pdf)', asset_path('www_slides.pdf')
    end

    When 'I add the localization description' do
      fill_markdown_editor('Description (in chosen language)', with: 'This is an example description')
    end

    When 'I navigate to a documents detail view' do
      click_on 'Show Details'
    end

    When 'I click on add a new localization' do
      click_on 'Add Language'
    end

    When 'I fill in the document data' do
      send :'When I fill in the internal document title'
      send :'When I fill in the internal document description'
      send :'When I add the localization language'
      send :'When I fill in basic localization data'
    end

    When 'I fill in basic localization data' do
      send :'When I upload the localization file'
      send :'When I add a localization title'
      send :'When I add the localization description'
    end

    When 'I fill in the localization data' do
      send :'When I fill in basic localization data'
      send :'When I add the localization language later on'
    end

    When 'I fill in the localization data for another language' do
      send :'When I fill in basic localization data'
      send :'When I add the localization language later on in another language'
    end

    When 'I submit the document data' do
      click_on 'Submit'
    end

    When 'I submit the localization data' do
      click_on 'Update Document'
    end

    Then 'This document exists' do
      expect(page).to have_content 'Example Document Title'
      expect(page).to have_content 'Example Document Description'
      expect(page).to have_content 'Assamese'
      expect(page).to have_link 'Add new Document'
    end

    Then 'There is a download link for the document' do
      url = page.find_link('Assamese')['href']
      expect(url).to include 'AS_v1.pdf'
    end

    Then 'the three localizations are shown' do
      expect(page).to have_content 'Assamese'
      expect(page).to have_content 'Bosnian'
      expect(page).to have_content 'Hindi'
    end
  end
end
Gurke.configure {|c| c.include Steps::Course }
