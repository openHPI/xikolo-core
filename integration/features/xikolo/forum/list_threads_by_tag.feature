@xi-833
Feature: List topics by tag
  In order to take part in discussions
  As a user
  I want to list existing topics by a tag

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And the forum is filled with topics

  Scenario: List topics by tag
    Given I am logged in
    When I open the general forum
    And I click on a tag
    Then I only see topic with that tag
