@xi-88 @implemented
Feature: Delete a course
  In order to clean up the course list
  As a manager
  I want to remove a course

  Background:
    Given an active course was created
    And I am logged in as a global course manager
    And I am on the course edit page

  Scenario: Delete a course
    When I delete the course
    Then I should see the course delete confirmation
    And the course should not be listed on the admin courses page
