Feature: Accept policy on login
  In order to satisfy some legal advocates
  As a User
  I have to accept new and updated policies on login

  Background:
    Given I am a confirmed user
    And there is a policy

  Scenario: Accept policy on password login
    Given I am on the login page
    When I fill in my email address
    And I fill in my password
    And I submit my credentials
    And I accept the policy
    Then I am logged in

  Scenario: Accept policy on SAML sign-up
    Given I am on the login page
    When I log in with "Single Sign-On (SAML)"
    And I decide to continue with a new account
    And I accept the policy
    Then I am logged in

  Scenario: Accept policy on SAML login
    Given I am on the login page
    And I have registered with "SAML"
    When I log in with "Single Sign-On (SAML)"
    And I accept the policy
    Then I am logged in

  Scenario: No need to accept policy twice
    Given I am on the login page
    And I have accepted current policy
    When I fill in my email address
    And I fill in my password
    And I submit my credentials
    Then I am logged in

  Scenario: No need to accept policy twice (SAML SSO)
    Given I am on the login page
    And I have accepted current policy
    And I have registered with "SAML"
    When I log in with "Single Sign-On (SAML)"
    Then I am logged in
