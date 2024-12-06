@xi-65
Feature: Unenroll from a course
  In order to reflect my interesets
  As a student
  I want to unenroll from a course in which I am enrolled

  Background:
    Given an active course with a section was created
    And a video item was created
    And I am confirmed, enrolled and logged in

  Scenario: Unenroll from a course
    Given I am on the course detail page
    When I unenroll from the course
    Then I am unenrolled from the course
    And I see a confirmation of unenrollment

  @feature:course_list
  Scenario: Keep data for re-enrollment
    Given I am on the item page
    And I am on the course detail page
    When I unenroll from the course
    Then I am on the dashboard page
    And I see a confirmation of unenrollment
    When I am on the course list
    And I enroll in the course
    And I am on the progress page
    Then the item should be completed
