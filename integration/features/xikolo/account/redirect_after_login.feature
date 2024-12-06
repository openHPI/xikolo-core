@feature:account.login
Feature: Redirect after login
  When I login from different pages
  As a user
  I want to be redirected to defined target pages.

  Background:
    Given I am a confirmed user
    And an active course was created

  Scenario: Redirect to dashboard by default
    Given I am on the homepage
    When I open the login page
    And I fill in my email address
    And I fill in my password
    And I submit my credentials
    Then I am logged in into my profile
    And I am on the dashboard page

  Scenario: Stay on course details page when logging in there
    Given I am on the course detail page
    When I open the login page
    And I fill in my email address
    And I fill in my password
    And I submit my credentials
    Then I am logged in into my profile
    And I am on the course detail page
