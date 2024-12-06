@xi-210 @accountRegistrationSteps @feature:account.registration @feature:account.login
Feature: Register a new account
  In order to use the platform
  As a not registered user
  I want to be able to quickly create an account and start learning.

  @flaky
  Scenario: Register with password
    Given I am on the registration page
    When I submit my account details
    Then I see an email confirmation message
    And I receive a welcome email with a link to confirm my email address
    When I follow the email confirmation link
    Then I am not logged in into my account
    And I am on the login page
    When I fill in my email address
    When I fill in my password
    When I submit my credentials
    Then I am logged in into my profile
    And I am on the dashboard page

  Scenario: Register with selected language
    Given I am on the registration page
    And I change the language to German
    When I submit my account details on German interface
    Then I see an email confirmation message in German
    And I receive a welcome email in German with a link to confirm my email address
