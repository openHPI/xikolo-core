Feature: Publish a global announcement
  In order to distribute information to every user on the platform
  As an administrator
  I want to write a global announcement

  Background:
    Given I am an administrator
    And I am logged in
    And I am on the news page

  @feature:announcements
  Scenario: Create a global announcement
    When I create a new announcement
    And I fill out the announcement fields
    And I save the announcement
    Then the announcement should be listed

  @feature:announcements
  Scenario: Receive a test email
    Given there exists an additional user
    When I create a new announcement
    And I fill out the announcement fields
    And I save and send the announcement in test mode
    Then I should receive a test email
    And the additional user should not receive a global announcement mail

  @feature:announcements
  Scenario: 'Save and send' button is disabled by default
    When I create a new announcement
    Then the save and send button is disabled
    When I enable the save and send button
    Then I can click save and send button

  @feature:announcements
  Scenario: Receive an email
    Given there exists an additional user
    When I create a new announcement
    And I fill out the announcement fields
    And I enable the save and send button
    And I save and send the announcement
    Then all users should receive an announcement email

  @wip
  Scenario: View stats
    # This test is skipped for now because the dashboard fails to load
    # The stats will move to the respective announcement's edit page soon
    Given there exists an additional user
    When I create a new announcement
    And I fill out the announcement fields
    And I save and send the announcement
    And I am on the admin dashboard
    Then I see a sending state
