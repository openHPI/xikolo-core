Feature: Course Progress function
  To now my personal course progress
  As a user
  I want to view my learning progress

  Background:
    Given an active course with a section was created
    And several items were created
    And I am confirmed, enrolled and logged in

  Scenario: Enter an item for the first time
    When I am on the progress page
    Given I count the unvisited items
    When I click on an unvisited item
    And I wait for 5 seconds
    And I am on the progress page
    Then the number of unvisited items is decreased by one

  Scenario: Unpublished items are not visible on progress page
    Given an unpublished video item was created
    When I am on the progress page
    Then there should be no unpublished item
