@feature:profile @feature:account.login
Feature: Change email address

  Background:
    Given I am logged in as a confirmed user
    Given the user has an additional confirmed email
    Given I am on the profile edit email page

  Scenario: Delete secondary email
    When I delete the secondary email
    Then I see my profile
