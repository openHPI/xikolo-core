@xi-229 @accountRegistrationSteps @feature:account.registration
Feature: User accidentally enters credentials in registration form
  In order to keep frustration at a minimum
  As a registered user
  I want to be logged-in even if I have used the wrong (registration instead of login) form

  Background:
    Given I am a confirmed user

  Scenario: Log in via registration form
    Given I am on the registration page
    When I submit my account credentials
    Then I am logged in into my profile
