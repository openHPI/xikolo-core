@alpha @xi-141
Feature: Commenting an answer in a topic
  In order to add my two cents to a certain answer
  As a student
  I want to comment an answer

  Background:
    Given an active course was created
    And I am confirmed, enrolled and logged in
    And a topic is posted in the general forum
    And the topic has an answer
    And the topic has subscribers

  Scenario: Commenting an answer in a forum
    Given I am on the general forum
    And I select the posted topic
    And I comment the answer
    When I submit my comment
    Then my comment is listed in the topic's comment list

  Scenario: Get a notification email about comment
    Given I commented the answer
    Then every subscriber received a comment notification email
    When I click on the topic link
    Then I should be on the topic page
