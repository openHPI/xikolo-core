Feature: Cookie consents
  In order to decide about my action regarding the current consent
  As a user
  I accept, decline or close the cookie consent

  Background:
    Given a cookie consent was set up
    When I am on the homepage
    Then I should see the cookie consent banner

  Scenario: Accept the consent
    When I click on the banner "Accept" button
    Given I am on the homepage
    Then I should not see the cookie consent banner

  Scenario: Decline the consent
    When I click on the banner "Decline" button
    Given I am on the homepage
    Then I should not see the cookie consent banner

  Scenario: Close the consent banner
    When I click on the banner "Close" button
    Given I am on the homepage
    Then I should see the cookie consent banner
