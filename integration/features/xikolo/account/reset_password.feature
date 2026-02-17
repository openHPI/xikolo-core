@alpha @xi-64 @accountResetPasswordSteps
Feature: Reset password
  In order to regain access to my account
  As a registered user
  I want to be able to reset my password.

  Background:
    Given I am a confirmed user
    And I am on the password reset page

  Scenario: Reset password via password forgot form
    When I request a password reset with my email address
    Then I see a password reset notice
    And I receive a password reset email
    When I click on the password reset link
    And I assign a new password
    Then I am able to login with my new password

  Scenario: Fail with invalid email
    When I request a password reset with an invalid email address
    Then I see an error about a non-existing email address

  Scenario: Fail with empty email
    When I request a password reset with an empty email address
    Then I see a form error

  Scenario: Fail with non matching passwords
    Given I request a password reset with my email address
    And I click on the password reset link
    When I assign two different passwords
    Then I see a form error

  Scenario: Fail with empty passwords
    Given I request a password reset with my email address
    And I click on the password reset link
    When I assign a new empty password
    Then I see a form error
