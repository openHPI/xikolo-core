@xi-1488
Feature: Gamification
  In order to always have my user score of gamification points present
  As a logged in user
  I want to see my user score within the global nav bar.

  Background:
    Given the gamification feature is enabled

    Scenario: See user score
      Given I am a confirmed user
      And I am logged in
      And I have the feature gamification enabled
      When I am on the homepage
      Then I can see my user score
      When I am on the dashboard achievements page
      Then I can see my course XP

    Scenario: I cannot see a user score when logged out
      Given I am on the homepage
      Then I cannot see any user score

    Scenario: I cannot see a user score when the feature is disabled
      Given I am a confirmed user
      And I am logged in
      When I am on the homepage
      Then I cannot see any user score
