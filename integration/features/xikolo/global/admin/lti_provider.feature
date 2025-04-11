Feature: Create a global LTI Provider
  In order to integrate external LTI tools
  As an administrator
  I want to create a new global LTI provider

  Background:
    Given I am an administrator
    And I am logged in
    And I am on the LTI provider admin page

  Scenario: Cancel modal to set privacy back to anonymized
    When I create a new LTI Provider
    And I fill in the LTI provider details
    And I select unprotected
    Then I see a modal to confirm the privacy option
    When I click cancel on the confirmation dialog
    Then the privacy value should be anonymized again
    When I submit the LTI provider form
    Then I am on the LTI provider admin page
    And the global LTI provider is available

  Scenario: Confirm modal to set privacy value unprotected
    When I create a new LTI Provider
    And I fill in the LTI provider details
    And I select unprotected
    Then I see a modal to confirm the privacy option
    When I click confirm on the confirmation dialog
    Then the privacy value should be unprotected
    When I submit the LTI provider form
    Then I am on the LTI provider admin page
    And the global LTI provider is available
