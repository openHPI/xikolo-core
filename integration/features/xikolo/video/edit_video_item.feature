@alpha @xi-192
Feature: A Teacher edits a video item
  In order to be able to create non-final video items
  As a teacher
  I want to edit the properties of an existing video item

  Background:
    Given an active course with a section was created
    And a video item was created
    And I am logged in as a course admin
    And I am on the course sections page
    And I have selected the video item for editing

  @flaky
  Scenario: Change the video's title
    When I edit the title to the video item
    And I save the changes of the video item
    Then I am on the item edit page
    And I see a message that the item was updated
    When I save and show the video item
    Then I am on the item page

  Scenario: Add subtitles to the video
    When I attach subtitles to the video
    And I save the changes of the video item
    Then I am on the item edit page
    And I see a message that the item was updated

  @flaky
  Scenario: Add a file to the description
    When I add an image to the description of the video item
    And I save the changes of the video item
    Then I am on the item edit page
    And I see a message that the item was updated
    And the video description contains the URI of the image
    When I click the preview tab
    Then the image is displayed

  @flaky
  Scenario: Change streams
    When I add streams to the video item
    And I save the changes of the video item
    Then I am on the item edit page
    And I see a message that the item was updated
