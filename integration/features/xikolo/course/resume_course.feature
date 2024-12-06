@xi-260 @xi-130
Feature: Course Resume function
  To continue working
  As a user
  I want to be redirected to where I stopped the last time

  Background:
    Given an active course with a section was created
    And several items were created
    And I am confirmed, enrolled and logged in

  Scenario: Enter a course for the first time
    When I select the course from the dashboard
    Then I should be on the first items page

  Scenario: Reenter the course at the last viewed item
    Given I worked on some items
    When I select the course from the dashboard
    Then I should be on last visited items page
