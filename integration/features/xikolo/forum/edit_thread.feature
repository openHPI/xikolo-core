Feature: Edit a topic
  In order to update my topic
  As a user
  I want to edit my posted topic

  Background:
    Given an active course with a section was created
    And I am a confirmed user
    And I posted a topic in the section's forum
    And I am logged in
    And I am on the general forum
    And I select the posted topic

  @flaky
  Scenario: Leaving the topic unchanged
    When I edit the topic
    And I update the topic
    Then the topic belongs to that section

  Scenario: Edit title
    When I edit the topic
    And I update the topic's title
    Then the topic should have the new title

  Scenario: Cancel editing
    When I edit the topic
    And I cancel editing
    Then I should not see the edit form
