@alpha @xi-154 @xi-941
Feature: Post a topic
  In order to get help on a certain topic
  As a student
  I want to post a topic in one of the courses' forum

  Background:
    Given an active course was created
    And I am confirmed, enrolled and logged in

  Scenario: Starting a topic in the general course context
    Given I am on the general forum
    And I start a new topic
    When I submit my topic
    Then my topic should be listed on the forum

  @flaky
  Scenario: Starting a topic in a course's weekly context
    Given an active section was created
    And I am on the section forum page
    And I start a new topic
    When I submit my post
    Then I am on the section forum page
    And my topic should be listed on the forum

  Scenario: Starting a topic in the technical issues context
    Given I am on the general forum
    And I change to the technical issues
    And I start a new topic
    When I submit my post
    Then my topic should not be listed on the forum
    And my topic should be listed on the technical issues forum

  # For Starting a topic in the video context see `video/discussion_in_forum.feature`

  Scenario: Selecting tags in the forum
    Given an explicit tag was created
    And I am on the general forum
    And I start a new topic
    And I select an existing tag
    And I create a new tag
    When I submit my post
    Then my topic should display the selected tags

  Scenario: Start a topic with a document attachment
    Given I am on the general forum
    And I start a new topic with a document attachment
    When I submit my post
    Then my topic should be listed on the forum
    And I can look at my topic
    And I see the uploaded document attachment

  Scenario: Start a topic with an image attachment
    Given I am on the general forum
    And I start a new topic with an image attachment
    When I submit my post
    Then my topic should be listed on the forum
    And I can look at my topic
    And I see the uploaded image attachment

  Scenario: Post duplicate topic
    Given I am on the general forum
    When I post a duplicate
    Then my topic should be listed only once
