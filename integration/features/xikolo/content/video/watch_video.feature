@alpha @xi-190 @xi-188
Feature: Student watches Video
  In order to be able to watch the videos on a wide variety of devices
  As a user (in the new version we will have less restrictions on accessing the material. All read-only actions can be performed without being logged in)
  I want to watch the video in different players.

  The video's metadata include
  * headline
  * description
  * duration
  * download links
    * video
    * slides
    * audio files
  # * podcast rss feed

  Background:
    Given an active course with a section was created
    And a video item was created
    And I am confirmed, enrolled and logged in

  Scenario: Successfully watching a video on the Xikolo dual stream player
    Given I am on the item page
    Then I should see the video in the Xikolo dual stream player
    And I should see the video's description


