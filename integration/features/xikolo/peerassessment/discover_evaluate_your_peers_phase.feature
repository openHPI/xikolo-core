Feature: Discover the Evaluate your peers phase
  In order to review and grade other solutions
  As a student
  I go to the third step and discover the step

  Background:
    Given an active course with a section was created
    And I am confirmed, enrolled and logged in
    And there is a fully configured peer assessment item
    And the "AssignmentSubmission" step is open

    And I started the assessment
    And I submitted a solution
    And the "Training" step is open
    And I advanced to the next step
    And I skipped the learn to grade phase

    Scenario: Visit open evaluate your peers phase
      Given the "PeerGrading" step is open
      When I go to the peer assessment evaluate your peers index page
      Then I should see the peer grading page
      And I should see an info box to find out how many submissions I have to review
      And I should see the "Evaluate Your Peers phase" panel
      When I click on the "Evaluate Your Peers phase" panel
      Then there should collapse an explanation about the process and the grading guidelines

    Scenario: No submissions for grading available
      Given the "PeerGrading" step is open
      When I go to the peer assessment evaluate your peers index page
      And I click on the "Review first peer" button
      Then I should see a flash message telling me that no submissions are available for grading

    Scenario: Start first peer review
      Given the "PeerGrading" step is open
      And there are some submissions to review
      When I go to the peer assessment evaluate your peers index page
      And I click on the "Review first peer" button
      Then I should see a student's answer
      And I should see the "general grading hints" panel
      And I should see the "assignment instructions" panel
      And I should see an info box about reporting submissions
      When I click on the "general grading hints" panel
      Then there should collapse some hints
      When I click on the "assignment instructions" panel
      Then there should collapse the assignment instructions

    Scenario: Submit a peer review
      Given the "PeerGrading" step is open
      And there are some submissions to review
      And there are grading rubrics and options
      When I go to the peer assessment evaluate your peers index page
      And I click on the "Review first peer" button
      Then I should not be able to submit an empty peer review
      When I select some grading options
      And I enter some written feedback
      And I click on submit
      Then I should see a submit peer review confirmation modal
      When I confirm
      Then I should see a message of successful peer review submission


