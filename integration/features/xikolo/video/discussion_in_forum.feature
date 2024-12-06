Feature: Post a topic under a video
  In order to get help on a certain topic related to a video
  As a student
  I want to post a topic in one of the courses' forum

  Background:
    Given an active course with a section was created
    And a video item was created
    And I am confirmed, enrolled and logged in

  @wip @flaky
  Scenario: Starting a topic in a video's context
    Given I am in a video's context
    When I start a new topic for the video
    And I submit my video post
    Then a new topic should be listed in the video's forum
    And the forum should be ordered reverse chronological, newest on top
