@xi-133
Feature: Moderate topic
  In order to moderate a topic
  As a teacher or admin
  I want to close topics, modify postings and delete posts or complete topics

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And the topic has an answer
    And the topic has a comment

  @wip
  Scenario: close a discussion topic
    Given that i am reading a topic
    When i click the "close topic" button
    Then the topic is marked as "closed"
    And no user can post to this topic any longer (no input controls for new answers or comments)
    And the button "close topic" is replaced by a "re-open topic" button
    And the topic shows a note that i closed the topic with my username and the current timestamp

  Scenario: edit a topic post
    Given I am reading a topic as teacher
    When I click the "edit" button of a specific post
    Then I can edit the topic text and save my changes
    Then the title and text of the post are changed
#    And the post gets a note indicating that i changed the content with my username and the current timestamp

  Scenario: edit a comment
    Given I am reading a topic as teacher
    When I click the "edit" button of a specific comment
    Then I can edit the comment text and save my changes
    Then the text of the comment is changed
#    And the comment gets a note indicating that i changed the content with my username and the current timestamp

  Scenario: cancel editing a comment
    Given I am reading a topic as teacher
    When I click the "edit" button of a specific comment
    And I cancel editing
    Then I should not see the edit form

  Scenario: cancel editing a answer
    Given I am reading a topic as teacher
    When I click the "edit" button of an answer
    And I cancel editing
    Then I should not see the edit form
