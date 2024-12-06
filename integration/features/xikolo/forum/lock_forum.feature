Feature: If a forum gets locked
  If a forum is locked
  As a student
  He can not post a new topic

  Background:
    Given an active course was created
    And the forum is filled with topics
    And I am logged in as a course admin
    And I am on the course edit page
    And I toggle the lock forum button
    And I submit the course edit page

  Scenario: Don't see new topic buttons on the general forum
    Given I am on the general forum
    Then I should not see the new topic button
    Then I should see a forum is locked message
    Given I select a topic
    Then I should not see the new topic button
    Then I should see a forum is locked message
