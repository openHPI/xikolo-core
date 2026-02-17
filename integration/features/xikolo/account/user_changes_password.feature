@xi-789 @feature:profile
Feature: Change own password
  In order to remember it better
  As a user
  I want to change my password

  Background:
    Given I am logged in as a confirmed user

  Scenario: Change own password
    Given I am on the profile page
    When I change my password
    Then I should be notified about successful password change

  Scenario: Log in with new password
    Given I am on the profile page
    When I change my password
    Then I should be able to log in with the new password
