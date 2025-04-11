Feature: Publish a course announcement
  In order to distribute information to every user in a course
  As a teacher
  I want to write a course announcement

  Background:
    Given an active course was created
    And I am logged in as a course admin
    And I am on the course announcements page

  Scenario: Create a course announcement
    When I create a new course announcement
    And I fill out the announcement fields
    And I save the announcement
    Then the announcement should be listed

  Scenario: Receive a test email
    Given there exists an additional user
    And the additional user is enrolled
    When I create a new course announcement
    And I fill out the announcement fields
    And I save and send the announcement in test mode
    Then I should receive a test email
    And the additional user should not receive a course announcement mail

  Scenario: Receive an email
    Given there exists an additional user
    And the additional user is enrolled
    And there is a third user
    When I create a new course announcement
    And I fill out the announcement fields
    And I enable the save and send button
    And I save and send the announcement
    Then all enrolled users should receive an announcement email
    And unenrolled users should not receive an email
