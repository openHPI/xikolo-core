@alpha
Feature: Stay logged in after a 404
  As a user
  Visiting a non existing course page
  I want to keep my user session

  Background:
    Given an active course was created

  @feature:course_list
  Scenario: Enroll as logged in user
    Given I am a confirmed user
    And I am logged in
    And I am on the course list
    When I enroll in the course
    Then I am enrolled in the course
    And I am on the course detail page
    When I visit an invalid course page
    Given I am on the course list
    Then I am logged in


