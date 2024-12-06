@xi-138
Feature: Unsubscribe topic
  In order to no longer be notified about updates to a topic
  As a user
  I want to unsubscribe from a topic

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And a topic is posted in the general forum
    And I am subscribed to the current topic

  Scenario: Unsubscribe via forum topic
    Given I am reading a forum topic
    When I unsubscribe from the current topic
    Then the topic shows a note that I am not subscribed to it
    And I see a follow button
    And the topic is removed from my subscribed topics

  Scenario: Unsubscribe via user profile
    Given I am logged in
    And I am browsing my notification settings
    When I unsubscribe from the current topic
    Then the topic is not listed under subscribed topics anymore
    And the topic is removed from my subscribed topics
