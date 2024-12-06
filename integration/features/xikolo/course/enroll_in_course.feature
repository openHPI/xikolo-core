@alpha @xi-26
Feature: Enroll in Course
  In order to fully participate (read and write) in a course
  as a user
  I want to enroll as a student in a course

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
    Then I receive a course welcome mail

  @feature:course_list @feature:account.login
  Scenario: Enroll as not logged in user
    Given I am a confirmed user
    And I am on the course list
    When I enroll in the course
    And I submit my login credentials
    Then I am enrolled in the course
    And I am on the course detail page
    Then I receive a course welcome mail

  @flaky
  Scenario: Enroll via API
    Given I am a confirmed user
    And I am enrolled in the active course
    Then I receive a course welcome mail
