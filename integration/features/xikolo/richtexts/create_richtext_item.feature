Feature: Teacher creates richtext item
  In order to add learning material to a course
  As a teacher
  I want to create a richtext item with interesting information.

  Background:
    Given an active course with a section was created
    And I am logged in as a course admin
    And I am on the course sections page

  Scenario: Successfully specifying an item to be of type "text"
    Given I add an item
    When I specify that the item is of type "Text"
    Then the item should offer the settings for items of type "richtext"
    When I fill out the minimal information for a richtext item
    And I save the richtext item
    Then I should be on the course sections page
    And the new richtext should be listed
