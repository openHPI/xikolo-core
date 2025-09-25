@feature:profile
Feature: Change profile birthday

  Background:
    Given I am logged in as a confirmed user
    And I am on the profile edit page

  Scenario:
    When I fill out the date of birth
    Then I see the new birthday date
