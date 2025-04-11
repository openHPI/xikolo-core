Feature: Administrator creates course
  In order to enable teachers to distribute wisdom amongst the masses
  As an administrator
  I should be able to create a new course.

  Background:
    Given I am an administrator
    And I am logged in
    And there exist some users
    And there exist some teachers
    And a public channel was created
    And I am on the course creation page

  Scenario: Create a course
    When I fill in the course data
    When I submit the course data
    Then I am on the new course page

  Scenario: Create an external course
    When I fill in the course data
    And I fill in the external course URL
    And I submit the course data
    Then I am on the new external course page


  # Scenario: Courses page provides button to create new course
  #   When the admin is on the courses page
  #   Then there should be a create new course button

  # Scenario: Opening the create course form
  #   When the admin is on the courses page
  #   And the admin clicks on the create course button
  #   Then the admin should be on the create new course page
  #   And the admin should be able to enter the required data

  # Scenario: Successfully creating a course with minimal data
  #   When the admin is on the create new course page
  #   And the admin enters and submits the minimal course data
  #   Then the admin should have successfully created the new course stub

  # Scenario: Successfully creating a course with full data
  #   When the admin is on the create new course page
  #   And the admin enters and submits the full course data
  #   Then the admin should have successfully created the new course

  # Scenario: Course creation fails due to duplicated shortcode
  #   Given a course "oldCourse" exists
  #   And the admin is logged in
  #   When the admin is on the create new course page
  #   And the admin tries to create another course with course_code "oldCourse"
  #   Then the course creation should have failed
