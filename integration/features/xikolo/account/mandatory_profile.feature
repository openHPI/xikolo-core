@feature:profile @feature:account.login
Feature: Mandatory profile

  Scenario: Complete profile
    Given there are mandatory profile fields
    And I am a confirmed user
    When I log in
    Then I am on the profile page
    And there is a notice with "To help us improve your learning experience, please fill out the required fields before proceeding on to your courses."
    When I fill out the mandatory profile
    And I am on the dashboard page
    Then I am on the dashboard page

