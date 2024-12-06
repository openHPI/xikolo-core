Feature: list collab space teams

  Background:
    Given an active course was created
    And I am confirmed, enrolled and logged in
    And a collab space team exists

  Scenario: See team in collab space list
    Given I am on the collab space list
    Then the collab space should be marked as team
    And I should not be able to join
