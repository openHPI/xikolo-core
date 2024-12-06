@xi-2746
Feature: Mark a course as completed
  In order to clean up my dashboard
  as a user
  I have the option to mark courses as completed

  Background:
    Given an active course was created
    And an archived course was created
    And I am confirmed, enrolled and logged in

  Scenario: Show completion button for all courses
    Given I am enrolled in the archived course
    When I am on the dashboard page
    Then all course can be marked as completed

  Scenario: Mark self-paced course as completed
    Given I am enrolled in the archived course
    When I am on the dashboard page
    And I mark the archived course as completed
    Then I am asked to confirm completion
    When I confirm completion of the course
    Then the modal should close automatically
    And the archived course is listed as completed course
