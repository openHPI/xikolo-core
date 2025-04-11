Feature: administrate team

  Background:
    Given an active course was created
    And a collab space team exists
    And I am confirmed, enrolled and logged in
    And I am a member of this team

  Scenario: restrict team admins right
    Given I am on the collab space administration page
    Then I should not be able to manage members
    And I should not be able to delete the collab space
    But I can change the collab space name
