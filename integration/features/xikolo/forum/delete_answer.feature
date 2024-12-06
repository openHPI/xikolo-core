Feature: Deleting an answer in a forum
  In order to remove an unwanted answer
  As a teacher
  I want to delete it

  Background:
    Given an active course was created

  Scenario: Delete an answer as teacher
    Given I am logged in as a course admin
    And a topic is posted in the general forum
    And the topic has an answer
    And I am on the topic page
    When I delete the answer
    Then I should be on the topic page
    And the answer should not be visible

  Scenario: Delete an answer as author
    Given I am confirmed, enrolled and logged in
    And I posted a topic in the general forum
    And the topic has an answer
    And I am on the topic page
    Then I should not be able to delete the post
