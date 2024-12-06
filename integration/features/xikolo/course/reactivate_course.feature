@feature:course_reactivation @feature:course_list
Feature: Reactivate a course
  In order to obtain a Record of Achievement in a self-paced course
  As a learner
  I want to reactivate a course and enjoy the perks of reactivating the course

  Background:
    Given an archived course was created
    And the archived course allows reactivation
    And I am a confirmed user
    And I am logged in
    And I have a valid voucher for course reactivation
    And an active section was created for an archived course
    And a main quiz item with questions and answers was created
    And the item deadline has passed

  Scenario: Enrolled learner can reactivate with voucher
    When I am on the course list
    And I enroll in the course
    Then I see a button to reactivate the course
    When I use the button to reactivate the course
    Then I am informed what reactivation means
    When I enter my voucher code
    And I click on the "Redeem" button
    Then I see a confirmation of reactivation
    And I do not see a button to reactivate the course

  Scenario: Enrolled learner can see upcoming course deadlines
    When I am on the course list
    And I reactivate the course with my voucher
    Then I see a confirmation of reactivation
    When I am on the archived course detail page
    Then I see a notification for the upcoming course expiration

  Scenario: Enrolled learner can access graded assignment after reactivation
    When I am on the course list
    And I reactivate the course with my voucher
    Then I see a confirmation of reactivation
    When I am on the item page of the archived course
    Then the quiz deadline is in the future
    When I start the quiz
    Then I confirm the main quiz pop-up
    Then I see the running quiz

