@xi-31
Feature: Edit section properties
  In order to correct mistakes in the course creation
  As a teacher
  I want to edit the section settings

  Background:
    Given an active course with a section was created
    And I am logged in as a course admin
    And I am on the course sections page

  Scenario: Successfully editing the section settings
    When I edit the sections settings
    Then the edited section should be listed
    And I should get visual feedback that the action was successful

  @wip
  Scenario: Successfully moving a section
    When I add a section
    And I fill in the section information
    And I save the section
    Then I should be on the course sections page
    When I move the lower section up
    Then I should see it in the correct order
