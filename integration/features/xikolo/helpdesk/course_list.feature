Feature: List courses in helpdesk
  In order to give feedback on a specific course
  as a user
  I want to select the course on the helpdesk

  Scenario: List public courses
    Given an active course was created
    And I am logged in as a confirmed user
    And I am on the homepage
    When I open the helpdesk
    Then the course should be listed in the category menu

  Scenario: List public courses if not logged in
    Given an active course was created
    And I am on the homepage
    When I open the helpdesk
    Then the course should be listed in the category menu

  Scenario: Pre-select course when in the course area
    Given an active course was created
    And I am logged in as a confirmed user
    And I am on the course detail page
    When I open the helpdesk
    Then the course should be pre-selected in the category menu
