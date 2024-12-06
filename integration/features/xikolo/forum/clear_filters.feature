@XI-1474
Feature: Clear filters on forum
  In order to see all topics after I searched for something
  As a user
  I want to clear all filters to see all topics

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And the forum is filled with topics


  Scenario: Clear filters after searching for a word
    Given I am logged in
    When I open the general forum
    And I fill in a search string
    And I click on the clear filter button
    Then the first 25 topics are listed ordered by creation time

  Scenario: Clear filters after searching for a tag
    Given I am logged in
    When I open the general forum
    And I click on a tag
    And I click on the clear filter button
    Then the first 25 topics are listed ordered by creation time

  Scenario: Clear filters after change sorting of topics
    Given I am logged in
    When I open the general forum
    And I sort the topics by best vote
    And I click on the clear filter button
    Then the first 25 topics are listed ordered by creation time
