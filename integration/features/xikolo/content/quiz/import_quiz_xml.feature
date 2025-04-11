@xi-1078
Feature: Import a quiz xml file
  In order to save time creating quizzes
  As a teacher
  I want to import quizzes from an xml file

  Background:
    Given an active course with a section was created
    And I am logged in as a course admin
    And I am on the course sections page

  @flaky
  Scenario: Importing a valid quiz xml file
    When I click the import quiz button
    Then an upload modal should appear
    When I select a valid XML file
    And I click on upload file button
    Then the quizzes should be listed in modal
    When I confirm the quizzes import
    Then a success modal should raise
    When I confirm the successful import
    Then I should be on the course sections page
    And the quizzes should be listed
    And the quizzes should not be published

  @flaky
  Scenario: Importing an invalid quiz xml file
    When I click the import quiz button
    Then an upload modal should appear
    When I select an invalid XML file
    And I click on upload file button
    Then an error modal should raise
    When I cancel the quizzes import
    Then none of the quizzes should be listed
