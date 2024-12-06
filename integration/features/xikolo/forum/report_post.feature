Feature: Report a post
  In order to avoid abuse in the forum
  As a student
  I want to report inappropriate behavior

  Background:
    Given an active course was created
    And a topic is posted in the general forum
    And the topic has an answer
    And the topic has a comment
    And I am confirmed, enrolled and logged in
    And I am on the topic page

  Scenario: Reporting a topic
    When I report the topic
    Then I should be on the topic page
    And I see a reporting success notice

  Scenario: Reporting a topic twice
    When I report the topic twice
    Then I see a reporting failure notice

  Scenario: Reporting an answer
    When I report the answer
    Then I should be on the topic page
    And I see a reporting success notice

  Scenario: Reporting a comment
    When I report the comment
    Then I should be on the topic page
    And I see a reporting success notice
