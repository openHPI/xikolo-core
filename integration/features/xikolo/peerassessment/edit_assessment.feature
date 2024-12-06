Feature: Edit a peer assessment
  In order to set up a peer assessment
  As a teacher
  I want to edit all necessary information

  Background:
    Given an active course with a section was created
    And I am logged in as admin
    And a new peer assessment item has been created
    And I am on the assessment edit page

  Scenario: Edit the assessment information
    When I fill in all information
    And I save the changes
    Then I see a success notification
    And all information are saved

  Scenario: Edit the file attachments
    When I click on the "File Attachment" menu point
    And I add a file to the dropzone
    Then I should see an uploaded file
    And I should be able to delete it

  Scenario: Choose workflow phases
    When I click on the "Workflow Phases" menu point
    And I choose all steps
    Then I should see a confirmation modal
    When I click on the "Create phases" menu point
    Then I should see a success message
    And I should see all step configurations

  Scenario: Configure workflow phases
    Given the peer assessment has new steps
    When I click on the "Workflow Phases" menu point
    And I configure all steps and save
    Then there should be a success message
    And the dates should be saved

  # Scenario: Edit grading rubrics
