@alpha @xi-192 @xi-71 @xi-198 @xi-404 @xi-194 @xi-152
Feature: Teacher creates video item
  In order to add videos to a course
  As a teacher
  I want to create an item which can hold a video.

  Background:
    Given an active course with a section was created
    And I am logged in as a course admin
    And I am on the course sections page

  Scenario: Successfully specifying an item to be of type "video"
    Given I add an item
    When I specify that the item is of type "Video"
    Then the item should offer the settings for items of type "video"

  @flaky
  Scenario: Successfully creating a video with minimal information
    Given I add an item
    When I specify that the item is of type "Video"
    And I fill out the minimal information for video item
    And I save the video item
    Then I should be on the course sections page
    And the new video should be listed

  @flaky
  Scenario: Successfully creating a video with downloadable content
    Given I add an item
    When I specify that the item is of type "Video"
    And I fill out the minimal information for video item
    And I attach downloadable content
    And I save the video item
    Then I should be on the course sections page
    And the new video should be listed

  @flaky
  Scenario: Downloading content
    Given a video item with downloadable content was created
    When I watch the created video
    Then I should see download buttons for all content
