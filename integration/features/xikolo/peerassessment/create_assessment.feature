Feature: Create a peer assessment
  In order to create a peer assessment
  As a teacher
  I want to set up an item linking to the peer assessment

  Background:
    Given an active course with a section was created
    And I am logged in as a course admin
    And I am on the course sections page
    And I add an item

  Scenario: Assessment form working
    When I specify that the item is of type "Peer Assessment"
    Then the page should have additional fields

  Scenario: Successfully creating the item
    When I add a title to the peer assessment item
    And I specify that the item is of type "Peer Assessment"
    And I choose to create a new assessment
    And I create the assessment item
    Then I should be on the assessment edit page
