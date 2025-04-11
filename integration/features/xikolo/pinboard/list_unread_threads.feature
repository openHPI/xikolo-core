@xi-1082
Feature: List unread topics
  To filter the forum
  As a student
  I want to see if I read a topic

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in

  Scenario: Reading a topic marks it read
    Given a topic is posted in the general forum
    And I am on the general forum
    And all topics are unread
    And I select the posted topic
    When I go back to the overview
    Then all topics are read
    When I am logged in as another user
    And I open the general forum
    Then all topics are unread

  Scenario: Posting a topic marks it read for the author
    Given I am on the general forum
    And I start a new topic
    When I submit my post
    Then my topic should be listed on the forum
    And my topic should be marked as read

  Scenario: Updating a read topic marks it unread
    Given a topic is posted in the general forum
    And I am on the general forum
    And all topics are unread
    And I select the posted topic
    When I go back to the overview
    Then all topics are read
    When the topic is answered
    And I wait for 5 seconds
    And I reload the page
    Then all topics are unread
