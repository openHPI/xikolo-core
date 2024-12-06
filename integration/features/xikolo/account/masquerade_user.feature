Feature: Masquerade as other user
  In order to debug user specific issues
  As GDPR admin I want to view the website as this specific user

  Scenario: Masquerade and demasquerade
    Given I am logged in as GDPR admin
    And there exists an additional user
    When I open the users list
    And I search for the other user
    And I masquerade as this user
    Then I should be masquerade as this user
    When I demasquerade
    Then I am again myself
