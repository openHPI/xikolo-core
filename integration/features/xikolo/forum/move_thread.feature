@xi-1331
Feature: Move a topic
  In order to moderate the forum
  As a teacher
  I want to move topics from one section to another

  Background:
    Given an active course with a section was created
    # TODO: Change to teacher
    And I am an administrator
    And I am enrolled in the active course
    And a topic is posted in the general forum
    And I am logged in
    And I am on the general forum
    And I select the posted topic

  Scenario: Moving a topic to a section
    When I edit the topic
    And I change the topic's section
    Then the topic belongs to that section

  Scenario: Moving a topic to Technical Issues
    When I edit the topic
    And I move the topic to Technical Issues
    Then the topic belongs to Technical Issues

  Scenario: Remove a topic from a section
    Given the topic belongs to a section
    When I edit the topic
    And I remove the topic's section
    Then the topic belongs to no section

  Scenario: Leaving a topic's section unchanged
    Given the topic belongs to a section
    When I edit the topic
    And I update the topic
    Then the topic belongs to that section
