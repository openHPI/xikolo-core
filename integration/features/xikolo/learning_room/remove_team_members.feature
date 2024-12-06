Feature: Remove team members

  Background:
    Given an active course was created
    And a collab space team exists
    And the team has members

  Scenario: remove team members as course admin
    Given I am logged in as a course admin
    And I am on the collab space administration page
    When I remove the team member
    And I visit the collab space page
    Then the member should not be listed
