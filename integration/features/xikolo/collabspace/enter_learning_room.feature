Feature: Enter a collab space

  Background:
    Given an active course was created
    And a collab space exists

  Scenario: Join public collab space as user
    Given I am confirmed, enrolled and logged in
    And I am on the collab space list
    When I join the collab space
    Then I should be on the collab space page
    And I should be listed in the member list

  Scenario: Join private collab space as user
    Given the collab space is private
    And I am confirmed, enrolled and logged in
    And I am on the collab space list
    When I request membership to the collab space
    Then I should be on the collab space page
    And my membership should be pending
