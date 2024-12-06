@xi-1581
Feature: Highlight unread answers
  As a participant of a topic
  I want every unread answer to be highlighted
  So I can distinguish the new part of the topic from the already seen part

  Background:
    Given an active course was created
    And I am confirmed, enrolled and logged in

  Scenario: Check new answers to a topic
    Given somebody posted a topic
    And someone replied
    Given I read the topic for the first time
    But 10 seconds later yet another person replies
    When I read the topic again
    Then the first answer doesn't look any different
    But the second answer is highlighted and therefore catches my attention

  Scenario: Check new comments to a topic
    Given somebody posted a topic
    And then someone wrote a comment on that topic
    Given I read the topic for the first time
    But after a while there is a new comment to the topic
    When I read the topic again
    Then the first comment doesn't look any different
    But the second comment is highlighted and catches my attention

  Scenario: Check new comments to an answer
    Given somebody posted a topic
    And someone answered the topic
    And someone commented this answer already
    Given I read the topic for the first time
    But after a while there is a new comment to this answer
    When I read the topic again
    Then the first comment doesn't look any different
    But the second comment is highlighted and catches my attention
