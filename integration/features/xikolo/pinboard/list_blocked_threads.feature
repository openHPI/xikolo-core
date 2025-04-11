Feature: List blocked topics
  In order to avoid inappropriate topics
  As a user
  I do not want to be confronted with blocked content

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And the topic is blocked

  Scenario: Seeing blocked topic as user
    Given I am confirmed, enrolled and logged in
    And I am on the general forum
    Then the topic should not be visible

  Scenario: Seeing blocked topic as admin
    Given I am logged in as admin
    And I am on the general forum
    Then the topic should be blocked

  Scenario: Seeing blocked and reviewed topic as user
    Given the topic is reviewed
    And I am confirmed, enrolled and logged in
    And I am on the general forum
    Then the topic should be visible
