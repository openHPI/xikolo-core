@feature:course_reactivation @feature:course_list
Feature: Configure a course for reactivation
  In order to allow students to reactivate a course
  As a teacher
  I want to configure the course for reactivation

  Background:
  Given an archived course was created
  And I am logged in as a course admin in the archived course

  Scenario: Teacher can toggle course reactivation
    When I am on the archived course edit page
    Then I see a toggle to enable reactivation of the course
    When I toggle the reactivation
    And I submit the course edit page
    And I am on the archived course detail page
    Then I see a button to reactivate the course
