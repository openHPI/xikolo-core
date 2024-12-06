# frozen_string_literal: true

module Steps
  module ImportQuizXml
    When 'I click the import quiz button' do
      click_on 'Import quizzes from XML'
    end

    Then 'an upload modal should appear' do
      expect(page).to have_content 'Choose the xml-file'
    end

    When 'I select a valid XML file' do
      attach_file 'xml', asset_path('quiz_import_valid_sample.xml')
    end

    When 'I select an invalid XML file' do
      attach_file 'xml', asset_path('quiz_import_invalid_sample.xml')
    end

    When 'I click on upload file button' do
      expect(page).to have_content 'Upload'
      click_on 'Upload'
    end

    Then 'the quizzes should be listed in modal' do
      expect(page).to have_content 'Quizzes preview'
      expect(page).to have_content 'Selftest 3.1'
      expect(page).to have_content 'Weekly Assignment 1.1'
      expect(page).to have_content 'Final Exam'
    end

    Then 'an error modal should raise' do
      expect(page).to have_content 'Errors occurred while validating quizzes'
    end

    Then 'a success modal should raise' do
      expect(page).to have_content 'Quizzes successfully imported!'
    end

    When 'I confirm the quizzes import' do
      click_on 'Import'
    end

    When 'I cancel the quizzes import' do
      expect(page).to have_content 'OK'
      click_on 'OK'
    end

    When 'I confirm the successful import' do
      expect(page).to have_content 'OK'
      click_on 'OK'
    end

    Then 'the quizzes should be listed' do
      expect(page).to have_content 'Selftest 3.1'
      expect(page).to have_content 'Weekly Assignment 1.1'
      expect(page).to have_content 'Final Exam'
    end

    Then 'none of the quizzes should be listed' do
      expect(page).to_not have_content 'Selftest 3.1'
      expect(page).to_not have_content 'Weekly Assignment 1.1'
      expect(page).to_not have_content 'Final Exam'
    end

    Then 'the quizzes should not be published' do
      expect(page).to have_content 'Item is not published'
      expect(page).to_not have_content 'Item is published'
    end
  end
end

Gurke.configure {|c| c.include Steps::ImportQuizXml }
