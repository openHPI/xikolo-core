Feature: Deleting a topic in a forum
  In order to remove an unwanted topic
  As a teacher
  I want to delete a topic

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And the topic has an answer

  @flaky
  Scenario: Delete a topic as teacher
    Given I am logged in as a course admin
    And I am on the topic page
    When I delete a topic
    Given I am on the general forum
    Then the topic should not be visible

  Scenario: Delete a topic as user
    Given I am confirmed, enrolled and logged in
    And I am on the topic page
    Then I should not be able to delete the post

  Scenario: Visiting a deleted topic
    Given the topic is deleted
    And I am logged in as a course admin
    And I am on the general forum
    Then the topic should not be visible
