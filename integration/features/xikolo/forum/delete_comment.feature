Feature: Deleting a comment in a forum
  In order to remove unwanted content
  As a teacher
  I want to delete comments

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And the topic has an answer

  Scenario: Delete a topic comment
    Given the topic has a comment
    And I am logged in as a course admin
    And I am on the topic page
    When I delete the topic comment
    Then I should be on the topic page
    And the topic comment should not be visible

  Scenario: Delete an answer comment
    Given the answer has a comment
    And I am logged in as a course admin
    And I am on the topic page
    When I delete the answer comment
    Then I should be on the topic page
    And the answer comment should not be visible

  Scenario: Delete an answer or a comment as author
    Given I am confirmed, enrolled and logged in
    And the topic has a comment by me
    And the answer has a comment by me
    And I am on the topic page
    Then I should not be able to delete the post
