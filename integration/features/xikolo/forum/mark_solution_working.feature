@alpha @xi-140
Feature: Mark a solution as working
  In order to help followers of a topic to make a decision
  As the owner of a topic or a teacher
  I want to mark a solution as working

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And the topic has an answer

  Scenario: Mark a solution as working as the owner of the topic
    Given I am the owner of the topic
    And I am logged in
    And I am on the general forum
    And I select the posted topic
    When I mark a solution as working
    Then the answer should be marked as working

  Scenario: Mark a solution as working as teacher
    Given I am logged in as a course admin
    And I am on the general forum
    And I select the posted topic
    When I mark a solution as working
    Then the answer should be marked as working
