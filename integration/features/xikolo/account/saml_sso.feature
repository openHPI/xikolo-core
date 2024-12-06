@xi-150 @feature:profile @feature:account.login
Feature: Sign up with SAML Single Sign-On (SSO)
  In order to use the platform
  As a user with a company account
  I want to be able to quickly create an account connected to my company identity and start learning.

  @feature:account.registration
  Scenario: Register a new account via SAML SSO
    Given I am on the login page
    When I log in with "Single Sign-On (SAML)"
    And I decide to continue with a new account
    Then I am logged in into my account
    And I am on the dashboard page
    And Provider "SAML" is shown on my profile page
    And I receive a welcome email without a link to confirm my email address

  Scenario: Connect SAML SSO to existing account with matching email
    Given I am Lassie
    And I have an authorization
    And I am on the login page
    When I log in with "Single Sign-On (SAML)"
    Then I am logged in into my account
    And I am on the dashboard page
    And I see an account connection success notice
    And Provider "SAML" is shown on my profile page twice

  Scenario: Connect SAML SSO to existing account with matching email while being logged in
    Given I am Lassie
    And I have an authorization
    And I am logged in
    And I am on the profile page
    When I connect another "Single Sign-On (SAML)" account
    Then I am on the profile page
    And I see an account connection success notice
    And Provider "SAML" is shown on my profile page twice

  Scenario: Connect SAML SSO to existing account with different e-mail address
    Given I am casual Lassie
    And I am on the login page
    When I log in with "Single Sign-On (SAML)"
    And I decide to connect SSO login with my existing account
    Then I am on the login page
    When I fill in my email address
    And I fill in my password
    And I submit my credentials
    Then I am logged in into my account
    And I am on the dashboard page
    And I see an account connection success notice
    And Provider "SAML" is shown on my profile page
    And I have my work e-mail as secondary e-mail address

  Scenario: Try to connect SAML SSO to existing account with private e-mail address I am logged in with but SSO is already connected to an old account
    Given I am casual Lassie
    And there is an account with my work e-mail and SSO connection
    And I am logged in
    And I am on the profile page
    When I connect another "Single Sign-On (SAML)" account
    # This is the current behaviour which is probably unintended (see XI-5159)
    Then I am unexpectedly logged in to my old account

  Scenario: Connect SAML SSO to existing account with different e-mail address while being logged in
    Given I am casual Lassie
    And I am logged in
    And I am on the profile page
    When I connect another "Single Sign-On (SAML)" account
    Then I am on the profile page
    And I see an account connection success notice
    And Provider "SAML" is shown on my profile page
    And I have my work e-mail as secondary e-mail address
