@alpha @xi-29 @implemented @teacher_role_test_missing
Feature: Add a new section to a course
  In order to structure a course in separate blocks
  As a teacher
  I want to add sections to a course

  Background:
    Given an active course was created
    And I am logged in as a course admin
    And I am on the course sections page

  Scenario: Successfully adding a section
    When I add a section
    And I fill in the section information
    And I save the section
    Then I should be on the course sections page
    And the section should be listed
    And the section should not be published

  Scenario: Successfully publishing a section
    When I add a section
    And I fill in the section information
    And I mark the section as public
    And I save the section
    Then the section should be published
