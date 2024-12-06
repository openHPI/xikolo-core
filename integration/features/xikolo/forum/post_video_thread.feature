@wip
Feature: Post a video topic
  In order to get help on a certain video
  As a student
  I want to post a topic linked to a video

  Background:
    Given an active course with a section was created
    And a video item was created
    And I am a confirmed user
    And I am enrolled in the active course
    And I am logged in

  Scenario: Posting a topic in a video context
    Given I am on the video page
    When I start a new video topic
    Then my video topic should be listed on the page
    When I open the video topic
    Then my topic belongs to the correct section and item

  Scenario: Editing a topic in a video context
    Given I am on the video page
    When I start a new video topic
    And I edit the video topic
    And I update the topic
    Then my topic belongs to the correct section and item

  Scenario: Posting in forum of a locked course
    Given a video topic exists
    And the course forum is locked
    And I am on the video page
    Then a new topic should be listed in the video's forum
    But there should be no video topic form

  Scenario: Posting in forum of a locked section
    Given a video topic exists
    And the section forum is locked
    And I am on the video page
    Then a new topic should be listed in the video's forum
    But there should be no video topic form

