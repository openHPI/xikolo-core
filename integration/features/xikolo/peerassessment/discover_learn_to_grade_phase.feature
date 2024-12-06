Feature: Discover the Learn to Grade phase
  In order to learn how to review and grade other solutions
  As a student
  I go to the second step and discover the step

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in
    And there is a fully configured peer assessment item
    And the "AssignmentSubmission" step is open
    And I started the assessment
    And I submitted a solution
    And I advanced to the next step

    Scenario: Visit locked learn to grade phase
      Given the "Training" step is locked
      When I go to the peer assessment learn to grade index page
      Then I should see the training page
      And I should see an info box about the unlock time
      And I should see the "Learn to Grade phase" panel
      When I click on the "Learn to Grade phase" panel
      Then there should collapse an explanation

    Scenario: Visit open but not started learn to grade phase
      Given the "Training" step is open
      When I go to the peer assessment learn to grade index page
      Then I should see the training page
      And I should see an info box to find out why the training has not started yet
      And I should see the "Learn to Grade phase" panel
      When I click on the "Learn to Grade phase" panel
      Then there should collapse an explanation

    Scenario: Start first training review
      Given there are some submitted solutions
      And the "Training" step is open
      And there is a course admin
      And there are grading rubrics and options
      And there are sample reviews
      And the Training step is open for student reviews
      When I go to the peer assessment learn to grade index page
      Then I should see the training page
      And I should see the "Learn to Grade phase" panel
      And I should see a button to request the first training sample
      When I click on the "Learn to Grade phase" panel
      Then there should collapse an explanation
      When I request the first training sample
      Then I should see a training sample
      And I should see the "Learn to Grade phase" panel
      And I should see the "general grading hints" panel
      And I should see the "assignment instructions" panel
      When I click on the "Learn to Grade phase" panel
      Then there should collapse an explanation
      When I click on the "general grading hints" panel
      Then there should collapse some hints
      When I click on the "assignment instructions" panel
      Then there should collapse the assignment instructions

    Scenario: Submit a training review
      Given there are some submitted solutions
      And the "Training" step is open
      And there is a course admin
      And there are grading rubrics and options
      And there are sample reviews
      And the Training step is open for student reviews
      When I go to the peer assessment learn to grade new sample page
      Then I should see a training sample
      And I should not be able to submit an empty training review
      When I select some grading options
      And I click on submit
      Then I should see a submit training review confirmation modal
      When I confirm
      Then I should see the training page
      And I should see a message of successful training review submission
