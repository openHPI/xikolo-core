Feature: Cant see new topic button in locked forum
  If a forum is locked
  As a student
  I can not post a new topic

  Background:
    Given an active course with a locked forum was created
    And I am a confirmed user
    And I am enrolled in the active course
    And I am logged in

  Scenario: Don't see new topic buttons
    Given I am on the general forum
    Then I should not see the new topic button
    Then I should see a forum is locked message
