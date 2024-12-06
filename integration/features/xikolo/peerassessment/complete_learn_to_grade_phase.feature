Feature: Complete the Learn to Grade phase
  In order advance to the next step and grade other solutions
  As a student
  I go to the second step and finally submit all training reviews

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in
    And there is a fully configured peer assessment item
    And the "AssignmentSubmission" step is open
    And I started the assessment
    And I submitted a solution
    And I advanced to the next step

    Scenario: Continue to the evaluate your peers phase
      Given there are some submitted solutions
      And the "Training" step is open
      And there is a course admin
      And there are grading rubrics and options
      And there are sample reviews
      And the Training step is open for student reviews
      And the "PeerGrading" step is open
      And I have trained enough
      When I go to the peer assessment learn to grade index page
      Then there should be an additional sample button
      When I click on the continue to the peer evaluation button
      Then I should see a confirmation modal to start the peer grading phase
      When I click on the start to evaluation your peers phase button
      Then I should see the peer grading page
