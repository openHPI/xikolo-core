@alpha @xi-136 @xi-941
Feature: Answer a topic
  In order to help my co-students with their problems (and also to learn by teaching)
  As a student
  I want to answer questions in the course's forum

  Background:
    Given an active course was created
    And I am a confirmed user
    And I am enrolled in the active course
    And a topic is posted in the general forum
    And the topic has subscribers
    And I am logged in
    And I am on the general forum
    And I select the posted topic

  Scenario: Answering a topic in the general forum
    When I submit an answer
    Then my answer is listed in the topic's answer list
    And every subscriber received an answer notification email

  Scenario: Following link in answer notification
    When I submit an answer
    And every subscriber received an answer notification email
    And I click on the topic link
    Then I should be on the topic page

  Scenario: Answering a topic in the general forum with an attached document
    When I submit an answer with an attached document
    Then my answer is listed in the topic's answer list
    And I see the uploaded document attachment

  Scenario: Answering a topic in the general forum with an attached image
    When I submit an answer with an attached image
    Then my answer is listed in the topic's answer list
    And I see the uploaded image attachment
