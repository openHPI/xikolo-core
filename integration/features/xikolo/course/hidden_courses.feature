@xi-1107 @xi-1211
Feature: Hidden courses
  In order to keep the course list clean from semi-private courses
  As an administrator
  I want to mark courses as hidden

  Background:
    Given a hidden course was created

  # Admins also cannot see hidden courses on this list, but that is not
  # a hard requirement, so we do not test it here.
  @feature:course_list
  Scenario: Hide to user from public list
    Given I am a confirmed user
    And I am logged in
    And I am on the course list
    Then the course should not be listed

  Scenario: Show to administrator on admin course list
    Given I am an administrator
    And I am logged in
    When I open the admin course list
    Then the course should be listed

  Scenario: Show to enrolled user on their dashboard
    Given I am a confirmed user
    And I am logged in
    And I am enrolled in the course
    When I am on the dashboard page
    Then the course should be listed
