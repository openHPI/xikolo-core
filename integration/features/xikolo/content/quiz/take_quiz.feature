@xi-32 @xi-40 @xi-46 @xi-338
Feature: Take a quiz
  In order to check my knowledge and understanding
  As an enrolled student in a course
  I want to take quizzes

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in

  Scenario: Taking a selftest
    Given a quiz item with one question and answers was created
    And I am on the item page
    Then I am redirected to a new submission for the quiz
    Then I see the running quiz
    When I select the correct answer
    And I submit the quiz
    Then I should see the assessment of my submission
    When I start the quiz again
    And I select the wrong answer
    And I submit the quiz
    Then I see the result of the submission with the wrong answer
    When I return to the item page
    Then I see the result of the submission with the wrong answer

  Scenario: Taking a selftest when deadline has passed
    Given a quiz item with one question and answers was created
    And the item deadline has passed
    And I am on the item page
    Then I should not be able to access the item

  Scenario: Taking a selftest again when deadline has passed and results are published
    Given a quiz item with one question and answers was created
    And I submitted the selftest once
    And the item deadline has passed
    And the quiz results are published
    And I am on the item page
    Then I see the result of the submission with the wrong answer

  Scenario: Taking a main quiz with unlimited attempts
    Given a main quiz item with one question and answers was created
    And the quiz has unlimited attempts
    And I am on the item page
    Then I see the quiz intro page
    When I start the quiz
    Then I confirm the main quiz pop-up
    Then I see the running quiz
    When I select the correct answer
    And I submit the quiz
    Then I see the split navigation on the quiz intro page
    When I retake the quiz
    Then I see the split navigation on the quiz intro page
    When I return to the item page
    Then I see the split navigation on the quiz intro page
    When I want to see my submissions
    Then I should see the assessment of my submission

  Scenario: Taking a main quiz without deadline
    Given a main quiz item with one question and answers was created
    And I am on the item page
    Then I see the quiz intro page
    When I start the quiz
    Then I confirm the main quiz pop-up
    Then I see the running quiz
    When I select the correct answer
    And I submit the quiz
    Then I see the split navigation on the quiz intro page
    When I retake the quiz selecting the wrong answer
    Then I see the result of the submission with the wrong answer
    When I return to the item page
    Then I see the result of the submission with the correct answer

  Scenario: Taking a main quiz with deadline not passed
    Given a main quiz item with one question and answers was created
    And the item deadline has not passed
    And I am on the item page
    Then I see the quiz intro page
    When I start the quiz
    Then I confirm the main quiz pop-up
    Then I see the running quiz
    When I select the correct answer
    And I submit the quiz
    Then I see the split navigation on the quiz intro page
    When I retake the quiz selecting the wrong answer
    Then I see the result of the submission with the wrong answer
    When I return to the item page
    Then I see the result of the submission with the correct answer

  Scenario: Taking a main quiz when deadline has passed
    Given a main quiz item with one question and answers was created
    And the item deadline has passed
    And I am on the item page
    Then I should not be able to access the item

  Scenario: Taking a main quiz again when deadline has passed and results are published
    Given a main quiz item with one question and answers was created
    And I am on the item page
    And I submitted a main quiz with wrong answer
    And the item deadline has passed
    And the quiz results are published
    And I am on the item page
    Then I see the result of the submission with the wrong answer
