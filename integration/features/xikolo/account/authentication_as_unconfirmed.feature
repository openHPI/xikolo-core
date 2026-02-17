@xi-24 @xi-298 @accountAuthenticationSteps
Feature: Authentication
  In order to not riot on the platform anonymously
  As a user
  I must be not able to log in before having confirmed my email

  Background:
    Given I am an unconfirmed user

  Scenario: Fail log when not confirmed
    When I visit the login page
    And I fill in my email address
    And I fill in my password
    And I submit my credentials
    Then I am not logged in into my profile
    And I see a confirmation required notice
