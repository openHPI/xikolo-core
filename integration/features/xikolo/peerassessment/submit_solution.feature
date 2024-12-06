Feature: Submit a peer assessment solution
  In order to submit a solution
  As a student
  I go to the first step and fill in my solution

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in
    And there is a fully configured peer assessment item
    And the "AssignmentSubmission" step is open
    When I go to the peer assessment landing page
    And I accept the code of honor
    And I start the assessment

    @flaky
    Scenario: Submit empty submission
      When I fill in nothing and submit
      And I confirm the submission warning
      Then I should see an error concerning the completeness of my submission

    @flaky
    Scenario: Submit filled in submission
      When I fill in the submission and submit
      And I confirm the submission warning
      Then I should see a success note about my submission
