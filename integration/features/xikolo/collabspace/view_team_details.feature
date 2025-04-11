Feature: View team details

  Background:
    Given an active course was created
    And I am confirmed, enrolled and logged in
    And a collab space team exists
    And I am a member of this team

  Scenario: List users as admins
    Given I am on the collab space page
    Then I should be listed as admin

  Scenario: Forbid users to leave team
    Given I am on the collab space page
    Then I should not be able to leave the team
