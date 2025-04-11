
Feature: Mark topic sticky
  In order to highlight important discussions
  As a teacher
  I want to mark topics as sticky

  Background:
    Given an active course was created
    And the forum is filled with topics


  Scenario: Marking a topic sticky
    Given I am logged in as a course admin
    And I am on the general forum
    When I select the fifth topic
    And I mark the topic sticky
    And I go to the general forum
    Then the sticky topic should be on top

  Scenario: Create a sticky topic as moderator
    Given I am logged in as a course admin
    And I am on the general forum
    And I start a new topic
    When I mark the new topic sticky
    And I submit my post
    Then the new topic should be sticky

  Scenario: Create a sticky topic as user
    Given I am confirmed, enrolled and logged in
    And I am on the general forum
    When I start a new topic
    Then I should not be able to mark it sticky
