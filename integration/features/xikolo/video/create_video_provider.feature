Feature: Admin creates video provider
  In order to organize my Vimeo accounts
  As an admin
  I want to create video providers

  Background:
    Given I am an administrator
    And I am logged in
    And I am on the video provider page

  Scenario: Create new Vimeo provider
    When I fill in the video provider form for Vimeo
    Then I should see the new video provider
    But I should not see the token
