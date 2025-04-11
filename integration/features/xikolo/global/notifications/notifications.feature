Feature: Disable email notifications
  In order to keep my Inbox clean
  As a user
  I want to disable all mail notifications

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And a topic is posted in the general forum

  Scenario: With default setting
    Given I am reading a forum topic
    When I subscribe to the current topic
    Then the topic shows a note that I am subscribed to it
    Given I wait for 2 seconds
    And the topic receives a comment
    Then I receive an email notification

  Scenario: Disable email notification
    Given I am reading a forum topic
    When I subscribe to the current topic
    Then the topic shows a note that I am subscribed to it
    When I disable all global mail notifications
    Given I wait for 2 seconds
    And the topic receives a comment
    Then I only have one mail
