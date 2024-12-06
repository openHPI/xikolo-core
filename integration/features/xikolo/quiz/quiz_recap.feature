Feature: Take a Quiz Recap session
  In order to check my knowledge and understanding
  As an enrolled student in a course
  I want to take a Quiz Recap session

  Background:
    Given an active course with a section was created
    And a quiz item with questions and answers was created
    And I am confirmed, enrolled and logged in
    And I have the feature quiz_recap enabled
    And I am on the course detail page

  Scenario: Quiz Recap with correct answer
    When I enter the Quiz Recap page
    Then I should see the instructions
    When I start a Quiz Recap session
    Then I should see a quiz question
    When I choose the correct answer
    Then I should see the results page

  Scenario: Quiz Recap with wrong answer
    When I enter the Quiz Recap page
    And I start a Quiz Recap session
    And I choose the wrong answer
    Then I should see a quiz question
    When I choose the correct answer
    Then I should see the results page with a review link
    When I click a review link
    Then I should see the reference page in a new window
