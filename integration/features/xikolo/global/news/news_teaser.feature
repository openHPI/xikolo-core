@wip @implemented
Feature: Publish a news with teaser
  In order to publish a news teaser
  As an administrator
  I want to write a news and find its teaser

  Background:
    Given I am an administrator
    And I am logged in
  Scenario: Write a global news
    When I write a global news with visual
    And I visit the homepage
    Then there is a news teaser
    When i log out
    And I visit the homepage
    Then there is a news teaser
