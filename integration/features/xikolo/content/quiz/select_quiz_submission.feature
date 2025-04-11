@XI-1528
Feature: Choose a submission via dropdown
  In order to see my previous answers

  Background:
    Given an active course with a section was created
    And a main quiz item with one question and answers was created
    And I am confirmed, enrolled and logged in
    And I am on the item page

  Scenario: Select quiz submission
    Given I submitted a main quiz with wrong answer
    Then I see the quiz intro page with results
    When I retake the quiz
    Then I should see an overview of my submissions
    Then I can choose one of my submissions
    When I choose the first submission
    Then I should see the result of the first submission
