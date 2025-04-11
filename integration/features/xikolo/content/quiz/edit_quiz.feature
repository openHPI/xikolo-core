@xi-1177 @xi-1358
Feature: Edit a quiz
  In order to correct mistakes in the quiz creation
  As a teacher
  I want to edit the quiz

  Background:
    Given an active course with a section was created
    And a quiz item with one question and answers was created
    And I am logged in as a course admin
    And I am on the item edit page

  Scenario: Switch question type
    When I open the questions tab
    And I edit the first question
    And I change the question type
    Then the new question type should be applied

  Scenario: Switch question with too many correct answers
    Given multiple quiz question answers are correct
    When I open the questions tab
    And I edit the first question
    And I change the question type
    Then the new question type should be applied
    And I should be notified that the question type needs to be reviewed

  Scenario: Add a new answer
    When I open the questions tab
    And I add a new answer
    Then the new answer should be visible

  Scenario: Edit answer
    When I open the questions tab
    And I edit the first answer
    And I change the answer text
    Then the new answer text should be applied

  Scenario: Delete a quiz question
    When I open the questions tab
    And I delete the first question
    And I confirm the deletion warning
    And I open the questions tab
    Then the question has been deleted successfully

  Scenario: Delete answer
    When I open the questions tab
    And I delete the first answer
    And I confirm the answer deletion warning
    And I open the questions tab
    Then the answer has been deleted successfully
