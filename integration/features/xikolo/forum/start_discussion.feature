@alpha @xi-135
Feature: Start a topic
  In order to communicate with my co-students
  As a student
  I want to start a topic in one of the courses' forum

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And I am logged in

  Scenario: Starting a topic in the general course context
    Given I am on the general forum
    And I start a new topic
    When I submit my topic
    Then my topic is listed on the forum

  Scenario: Starting a topic in a course's weekly context
    Given an active section was created
    And I am on the section forum page
    And I start a new topic
    When I submit my topic
    Then I am on the section forum page
    And my topic is listed on the forum
