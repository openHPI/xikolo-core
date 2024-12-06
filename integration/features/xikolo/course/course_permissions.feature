@xi-1964 @implemented
Feature: Assign users to special groups
  In order to grant users additionanl rights within one course
  As an administrator
  I want to assign users to predefined special groups

  Background:
    Given an active course with teachers was created
    And I am logged in as a course admin
    And there exists an additional user

  Scenario: View Permissions
    When I am on the course permissions page
    Then I see the members of the teacher group
    And I see the granted roles for the teacher group
    Then I see the granted roles for the student group
    And I see the granted roles for the student group

  Scenario: Remove user from special group
    Given I am on the course permissions page
    When I remove the first teacher
    Then the user should not be teacher

  Scenario: Assign user to special group
    Given I am on the course permissions page
    When I add the additional user to the teacher group
    Then the user should be teacher
