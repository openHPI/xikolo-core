@feature:profile
Feature: Visit profile

  Background:
    Given I am logged in as a confirmed user
    And I am on the profile page

  Scenario:
    Then I see my profile
