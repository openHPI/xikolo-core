Feature: Start a peer assessment
  In order to start a peer assessment
  As a student
  I go to the landing page and start the assessment

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in
    And there is a fully configured peer assessment item

  @flaky
  Scenario: With a locked assessment
    When I go to the peer assessment landing page
    Then there should be no start button

  @flaky
  Scenario: With an open assessment
    Given the "AssignmentSubmission" step is open
    When I go to the peer assessment landing page
    And I accept the code of honor
    And I start the assessment
    Then I should be in the first step

  @flaky
  Scenario: Not confirming the code of honor
    Given the "AssignmentSubmission" step is open
    When I go to the peer assessment landing page
    And I start the assessment
    Then I should see a request to accept the code of honor first
