@feature:profile
Feature: Change profile image

  Background:
    Given I am logged in as a confirmed user
    And I am on the profile page

  Scenario:
    When I upload a profile image
    Then I see the new profile image
