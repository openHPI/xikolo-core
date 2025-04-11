@xi-1328
Feature: If a section forum page gets locked
  If a section forum page is locked
  As a student
  I can not post a new topic

  Background:
    Given an active course with a section was created
    And a topic is posted in the section's forum
    And the topic has an answer
    And I am logged in as a course admin
    And I am on the course sections page
    When I mark the section forum as closed

  Scenario: Don't see new topic buttons on the section forum page
    Given I am on the section forum page
    Then I should not see the new topic button
    And I should see a section is locked message
    Given I select a topic
    Then I should not see the new topic button
    And I should see a section is locked message
