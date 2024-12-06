Feature: Add team members

  Background:
    Given an active course was created
    And users are enrolled in the course
    And a collab space team exists
    And I am logged in as a course admin
    And I am on the collab space administration page

  Scenario: as course admin add team admin
    When I select a user from the list
    And I mark the member as admin
    And I create the membership
    Then the member should be listed as Admin

  Scenario: as course admin add team mentor
    When I select a user from the list
    And I mark the member as mentor
    And I create the membership
    Then the member should be listed as Mentor
