@xi-573
Feature: Change user password as admin
  In order help locked out users
  As a GDPR admin
  I want to change a users password

  Background:
    Given I am a GDPR administrator
    And I am logged in
    And there exists an additional user

  Scenario: Change users password
    Given I am on the additional user's detail page
    When I set a new password for the user
    Then I should be notified about successful password change

  Scenario: Log in with new password
    Given I am on the additional user's detail page
    When I set a new password for the user
    Then the additional user should be able to log in with the new password
