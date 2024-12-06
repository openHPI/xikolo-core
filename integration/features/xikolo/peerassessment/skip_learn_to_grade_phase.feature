Feature: Skip the Learn to Grade phase
  As a student
  I go to the second step and skip it

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in
    And there is a fully configured peer assessment item
    And the "AssignmentSubmission" step is open
    And I started the assessment
    And I submitted a solution
    And I advanced to the next step

    Scenario: Skip learn to grade phase in which no training examples are available yet
      Given the "Training" step is open
      And the "PeerGrading" step is open
      When I go to the peer assessment learn to grade index page
      And I click on the next step
      Then I should see a confirmation modal to start the peer grading phase
      When I click on the start to evaluation your peers phase button
      Then I should see the peer grading page

    Scenario: Skip learn to grade phase in which training examples are available
      Given there are some submitted solutions
      And there is a course admin
      And there are grading rubrics and options
      And there are sample reviews
      And the "Training" step is open
      And the Training step is open for student reviews
      And the "PeerGrading" step is open
      When I go to the peer assessment learn to grade index page
      And I click on the continue to the peer evaluation button
      Then I should see a confirmation modal to start the peer grading phase
      When I click on the start to evaluation your peers phase button
      Then I should see the peer grading page
