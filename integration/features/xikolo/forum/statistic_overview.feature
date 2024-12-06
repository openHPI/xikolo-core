@xi-497 @xi-705 @xi-847
Feature: forum Overview
  In order to see the significance of a forum post
  As a user
  I want to get a statistic of views, answers and votes

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And I am confirmed, enrolled and logged in


  Scenario: Answering and commenting increases the 'response' count
    Given I am on the general forum
    Then the topic is not worked on
    When the topic is answered and commented
    Then the reply count should be two

  Scenario: Voting changes the 'votes' count
    Given I am on the general forum
    Then the topic is not worked on
    When the topic is voted on
    Then the votes count should change
