Feature: Create a standalone teacher
  In order to add teacher without a connection to a user
  As a GDPR administrator
  I want to create a new standalone teacher

  Background:
    Given I am a GDPR administrator
    And I am logged in
    And I am on the teacher list

  Scenario: Successfully create a teacher
    When I create a new teacher
    And I fill in a name
    And I submit the teacher information
    And I visit the teacher list
    Then I see the new teacher
    And the teacher has his information configured
