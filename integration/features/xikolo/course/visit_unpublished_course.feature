Feature: Show unpublished courses to teachers
  In order to get informed about an unpublished course
  as a teacher
  I want to read the course information

  Background:
    Given an unpublished course was created

  Scenario: Read course information as admin
    Given I am an administrator
    And I am logged in
    When I am on the course detail page
    Then I should see course details

  Scenario: Read course information as teacher
    Given I am logged in as a course admin
    When I am on the course detail page
    Then I should see course details

  @feature:course_list
  Scenario: Don't see the course listed as user
    Given I am a confirmed user
    And I am logged in
    When I am on the course list
    Then the course should not be listed

  @feature:course_list
  Scenario: Don't read course information as user
    Given I am a confirmed user
    And I am logged in
    When I am on the course detail page
    Then I see a friendly 404 page

  Scenario: Show to administrator on admin course list
    Given I am an administrator
    And I am logged in
    When I open the admin course list
    And I filter for courses in preparation
    Then the course should be listed
