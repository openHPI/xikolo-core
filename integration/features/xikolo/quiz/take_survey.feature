@xi-1995
Feature: Take a survey
  In order to provide feedback
  As an enrolled student in a course
  I want to take a survey

  Background:
    Given an active course with a section was created
    And a survey item with questions and answers was created
    And I am confirmed, enrolled and logged in

  Scenario: Taking the survey
    Given I am on the item page
    When I select an answer
    And I submit the survey
    Then I should see the survey confirmation

  Scenario: Taking the survey when deadline has passed
    Given the item deadline has passed
    And I am on the item page
    Then I should not be able to access the item
