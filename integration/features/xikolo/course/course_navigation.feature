@alpha @xi-26
Feature: Enroll in Course
  In order to fully participate (read and write) in a course
  as a user
  I want to enroll as a student in a course

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am logged in
    And I am on the course list
    When I enroll in the course

  @feature:course_list
  Scenario: Enroll as logged in user
    Given I am on the course detail page
    Then I should see the course navigation
    Then I should not see the course teacher navigation
