Feature: Course subscriptions trigger notifications
  In order to be notified about new topics in a course
  As a subscribed learner
  I want to receive an email when someone posts a new topic

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course

  Scenario: Receive notification email for new topic after subscribing to course
    When I subscribe to the current course
    And another user posts a new topic in the current course
    Then I receive a course subscription notification email

  Scenario: No notification after unsubscribing from course
    Given I am subscribed to the current course
    When I unsubscribe from the current course
    And another user posts a new topic in the current course
    Then I do not receive a course subscription notification email
