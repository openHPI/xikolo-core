@xi-1339
Feature: Closing a topic in a forum
  In order to close an unwanted or deprecated topic
  As a teacher
  I want to close a topic

  Background:
    Given an active course was created
    And an active section was created
    And a topic is posted in the section's forum
    And the topic has an answer
    And I am logged in as a course admin
    And I am on the general forum
    And I select the posted topic


  Scenario: Close a topic as teacher
    When I close a topic
    Then I should see a entry is closed message
    And I cannot create a new answer
    And I cannot see the add comment button
    And I should see the reopen button
    When I open the general forum
    Then the topic should have closed icon

  Scenario: Reopen a previously closed topic as teacher
    Given the topic is closed
    When I reopen a topic
    Then I can create a new answer
    And I can see the add comment button
    And I should see the close button
