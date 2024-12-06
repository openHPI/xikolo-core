Feature: One click unsubscription of forum notifications
  In order to disable email notifications about forum activity
  as a user
  I want to use the link provided in emails

  Background:
    Given I am a confirmed user
    And an active course was created
    And I posted a topic in the general forum
    And the topic has an answer with notification

  Scenario: Use disable link as logged in user
    Given I am logged in
    When I open my forum notification email
    And I click the forum notification disable link
    Then I should be on the profile settings page
    And forum notifications should be turned off
