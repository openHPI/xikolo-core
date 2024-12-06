Feature: Discuss in a collabspace

  Background:
    Given an active course was created
    And I am confirmed, enrolled and logged in
    And a collab space exists
    And I am a member of this team

  Scenario: Follow link to topic in collabspace
    Given the collab space is a team
    And the team has members
    Given I am on the collab space forum page
    And I start a new topic
    When I submit my post
    And I am logged in as another team member
    Then I should get a notification email about a new topic
    When I click on the topic title
    Then I should be on a collab space topic page
