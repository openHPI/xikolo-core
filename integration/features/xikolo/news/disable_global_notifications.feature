Feature: One click unsubscription of email notifications
  In order to disable email notifications
  as a user
  I want to use the link provided in emails

  Background:
    Given I am a confirmed user

  Scenario: Use disable link as logged in user
    Given a global announcement was created
    And the announcement was sent
    And I am logged in
    When I open my announcement email
    And I click the global disable link
    Then I should be on the profile settings page
    And email notifications should be turned off

  Scenario: Use disable link while being logged out
    Given a global announcement was created
    And the announcement was sent
    When I open my announcement email
    And I click the global disable link
    Then I am on the home page
    And email notifications should be turned off

  Scenario: Use a disable link with invalid email address
    When I use a disable link with invalid email address
    Then I am on the home page
    And email notifications should not be turned off

  Scenario: Use a disable link with invalid hash
    When I use a disable link with invalid email address
    Then I am on the home page
    And email notifications should not be turned off
