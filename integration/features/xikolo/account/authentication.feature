@xi-24 @xi-298 @accountAuthenticationSteps
Feature: Authentication
  In order to use Xikolo with my personal settings and data
  As a user
  I want create a profile and sign in and out.

  Background:
    Given I am a confirmed user

  Scenario: Sign in with valid credentials
    When I visit the login page
    And I fill in my email address
    And I fill in my password
    And I submit my credentials
    Then I am logged in into my profile
    And I am on the dashboard page

  Scenario: Sign in with valid case insensitive credentials
    When I visit the login page
    And I fill in my upcase email address
    And I fill in my password
    And I submit my credentials
    Then I am logged in into my profile
    And I am on the dashboard page

  Scenario: Fail log in with invalid credentials
    When I visit the login page
    And I fill in my upcase email address
    And I fill in a wrong password
    And I submit my credentials
    Then I am not logged in into my profile
    And I see a login failed notice

  Scenario: Sign out
    Given I am logged in
    And I am on the dashboard page
    When I log out
    Then I am on the home page
    And I am logged out

  Scenario: Log in with SAML SSO
    Given I have registered with "SAML"
    When I visit the login page
    And I log in with "Single Sign-On (SAML)"
    Then I am logged in into my profile
    And I am on the dashboard page
