Feature: One click unsubscription of email announcements
  In order to disable email announcements
  as a user
  I want to use the link provided in emails

  Background:
    Given I am a confirmed user

  Scenario: Use disable link as logged in user
    Given a global announcement was created
    And the announcement was sent
    And I am logged in
    When I open my announcement email
    And I click the announcement notification disable link
    Then I should be on the profile settings page
    And announcement notifications should be turned off
