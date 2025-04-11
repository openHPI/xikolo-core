@xi-93
Feature: Subscribe to topic
  In order to be notified about activity in a specific topic
  As a user
  I want to subscribe to that topic

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And a topic is posted in the general forum

  Scenario: Subscribe to a topic
    Given I am reading a forum topic
    When I subscribe to the current topic
    Then the topic shows a note that I am subscribed to it
    And I see an unfollow button
    And the topic is added to my subscribed topics
