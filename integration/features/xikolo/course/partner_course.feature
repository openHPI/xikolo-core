Feature: Partner course only visble for partners
  In order to let only members of a certain user group (here: partners) take a course
  As an administrator
  I want to have courses with group restrictions, that are only visible for group members

  Scenario: Create course with partner restriction
    Given the company.partner group exists
    And I am an administrator
    And I have the feature course.access-group enabled
    And I am logged in
    And there is a configuration for access_groups
    And a public channel was created
    And I am on the course creation page
    When I fill in the course data
    And I select the partner group restriction
    And I submit the course data
    Then I am on the new course page
    When I edit the current course
    Then the group Partners is selected

  @feature:course_list
  Scenario: Partner course not visible for normal user
    Given the company.partner group exists
    And an active partner course was created
    And I am a confirmed user
    And I have the feature course.access-group enabled
    And I am logged in
    When I am on the course list
    Then the course should not be listed

  @feature:course_list
  Scenario: Partner can enroll in partner course
    Given the company.partner group exists
    And an active partner course was created
    And I am a confirmed user
    And I have the feature course.access-group enabled
    And I am in the company.partner group
    And I am logged in
    When I am on the course list
    Then I see the course Partner Course
    When I enroll in the course
    Then I am enrolled in the course
