Feature: Add alternative sections to a course
  In order to offer alternative content within a section
  As a teacher
  I want to add alternative sections to a course

  Background:
    Given an active course with a section was created
    And I am logged in as a course admin
    And I am on the course sections page

  @feature:alternative_sections.create
  Scenario: Successfully adding an alternative section
    When I add an alternative section
    And I fill in the alternative section information
    And I save the section
    Then I should be on the course sections page
    And I should get visual feedback that the alternative section was created
    And the alternative section and its description should be listed
