@xi-1748 @implemented
Feature: Invite only course
  In order to let only selected participants take a course
  As a teacher
  I want to have an invite only course

  Background:
    Given an 'invite only' course was created

  @feature:course_list
  Scenario: User cannot enroll himself
    Given I am a confirmed user
    And I am logged in
    And I am on the course list
    Then I should not see a button labeled "Enroll"
    When I am on the course detail page
    Then I should not see a button labeled "Enroll me now"

  Scenario: Enroll user manually
    Given I am logged in as a course admin
    And there exists an additional user
    And I am on the student enrollments page
    When I search for the additional user
    And I enroll the user manually
    Then the user should be enrolled in the course
