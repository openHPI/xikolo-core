Feature: Add course visuals
  In order to provide an image or teaser video for a course
  As a teacher
  I can add visuals to the course

  Background:
    Given an active course was created
    And I am an administrator
    And I am logged in
    And I am on the course visuals edit page

  Scenario: Add a visual to the course
    When I attach a course visual
    And I submit the course visual
    Then I am on the course detail page
    And I see the visual

  Scenario: Create a course with video
    Given I have the feature vimeo_player enabled
    When I select a stream
    And I submit the course visual
    Then I am on the course detail page
    And the video is rendered in the video player
