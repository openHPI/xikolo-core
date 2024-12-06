Feature: Unblock a post
  In order to prevent censorship
  As an admin
  I want to review and unblock posts reported as inappropriate behavior

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And the topic is blocked
    And I am logged in as admin
    And I am on the topic page

  Scenario: Unblocking a topic
    When I unblock the topic
    Then the topic should not be blocked
