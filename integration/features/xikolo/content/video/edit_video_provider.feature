Feature: Admin edits video provider
  In order to organize my Vimeo accounts
  As an admin
  I want to view and edit existing video providers

  Background:
    Given I am an administrator
    And I am logged in
    And I am on the video provider page

  Scenario: Edit provider
    When I edit the provider
    And I change the name
    Then the name should be updated
