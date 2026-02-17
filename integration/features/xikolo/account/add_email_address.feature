@feature:profile
Feature: Change email address

  Background:
    Given I am logged in as a confirmed user
    Given I am on the profile edit email page

  Scenario: Add new address
    When I add a new email address
    Then I receive a welcome email in English with a link to confirm my new email address
    When I follow the email confirmation link
    Then I am on the dashboard page
