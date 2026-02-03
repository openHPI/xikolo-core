Feature: Course Syllabus
  To have an overview over a course's content
  As a user
  I want to view the course syllabus and be
  able to have a look at previewable content

  Background:
    Given an active course with a section was created
    And several non-previewable and a previewable item were created

  Scenario: Visit course syllabus as a logged in and enrolled user
    Given I am confirmed, enrolled and logged in
    When I visit the syllabus page
    Then I see the list of course items
    And I do not see an infobox that informs me I visit the syllabus page in open mode
    When I click on an non-previewable item
    Then I see a non-previewable item

  @wip
  @feature:open_mode
  Scenario: Visit course syllabus as a logged in but unenrolled user with open mode being enabled
    Given Open Mode is enabled
    And I am a confirmed user
    And I am logged in
    When I visit the syllabus page
    Then I see the list of course items
    And I see an infobox that informs me I visit the syllabus page in open mode
    When I hover over an non-previewable item
    Then I see a tooltip that informs me the item cannot be previewed
    When I click on a previewable item
    Then I see the previewable item

  Scenario: Visit course syllabus as a logged in but unenrolled user with open mode being disabled
    Given I am a confirmed user
    And I am logged in
    When I visit the syllabus page
    Then I am redirected to the course detail page
    Then I see a message that I should enroll in the course

  Scenario: Visit course syllabus as an anonymous user with open mode being disabled
    When I visit the syllabus page
    Then I am redirected to the course detail page
    Then I see a message that I should login to proceed

  @wip
  @feature:open_mode
  Scenario: Visit course syllabus as an anonymous user with open mode being enabled
    Given Open Mode is enabled
    When I visit the syllabus page
    Then I see the list of course items
    And I see an infobox that informs me I visit the syllabus page in open mode
    When I hover over an non-previewable item
    Then I see a tooltip that informs me the item cannot be previewed
    When I click on a previewable item
    Then I see the previewable item
