@feature:profile @feature:account.login
Feature: Mandatory profile

  Background:
    Given I am logged in as a confirmed user
    Given I am on the profile edit page

  Scenario: Complete profiles
    When I fill out the profile form
    And I am on the dashboard page
    Then I am on the dashboard page
