Feature: A Teacher edits a video item subtitles
  In order to automatically transcript and translate videos
  As a teacher
  I want to manage the video's subtitles in TransPipe

  Background:
    Given an active course with a section was created
    And a video item was created
    And there is a configuration for transpipe
    And I am logged in as a course admin
    And I am on the course sections page
    And I have selected the video item for editing

  Scenario: TransPipe enabled
    Then there is no dropzone for the subtitles
    And I see the attached subtitles in a specific language
    And there is a link to add the subtitles via transpipe
