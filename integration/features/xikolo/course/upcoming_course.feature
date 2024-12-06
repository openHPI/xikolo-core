Feature: Upcoming Course
  In order to prepare for a course
  As a learner
  I want to be informed about a course's details on its public landing page

  Background:
    Given an upcoming course was created
    And I am confirmed, enrolled and logged in

  Scenario: Preview course details
    When I am on the course detail page
    Then I should see a countdown for "Course starts in"
    When I try to visit the course content
    Then I see a message that there is no public course content
    And I am redirected to the course detail page
