Feature: Choose alternative section within a course
  In order to select my preferred content within a section
  As a user
  I want to choose the alternative section I'm interested in

  Background:
    Given an active course was created
    And alternative parent and child sections were created
    And items for child alternatives were created
    And I am confirmed, enrolled and logged in
    And I am on the parent section page

  Scenario: View decisions for alternative sections
    Then the alternative sections and its descriptions should be listed

  Scenario: Select an alternative section
    When I select the first alternative section
    Then I should be on the items page of the first alternative section
    And the first alternative section should be listed
    But the second alternative section should not be listed

  Scenario: View progress with an alternative section
    When I select the first alternative section
    And I am on the progress page
    Then the first alternative section should be listed
    But the second alternative section should not be listed

  Scenario: Select two alternative sections
    When I select the first alternative section
    And I select the second alternative section
    Then I should be on the items page of the second alternative section
    And both alternative sections should be listed

  Scenario: View progress with two alternative sections
    When I select the first alternative section
    And I select the second alternative section
    And I am on the progress page
    Then both alternative sections should be listed
    And the course progress should only count one alternative section
