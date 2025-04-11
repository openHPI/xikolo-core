@xi-144
Feature: List topics
  In order to take part in discussions
  As a user
  I want to list existing topics

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And the forum is filled with topics

  Scenario: List topics
    Given I am logged in
    When I open the general forum
    Then the first 25 topics are listed ordered by creation time
    #And each topic shows title, author, date, tags, voting score and number of read and unread postings in the topic
    And I have a button to start a new topic

  Scenario: List topics from second page
    Given I am logged in
    When I open the general forum
    And I open the second forum page
    Then the second 25 topics are listed ordered by creation time
    #And each topic shows title, author, date, tags, voting score and number of read and unread postings in the topic
    And I have a button to start a new topic

  @wip
  Scenario: Sort topics by latest

  Scenario: Sort topics by votes
    Given I am logged in
    When I open the general forum
    And I sort the topics by best vote
    Then the first 25 topics are listed ordered by best votes
