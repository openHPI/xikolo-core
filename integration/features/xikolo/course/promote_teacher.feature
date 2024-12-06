@alpha @xi-344 @implemented
Feature: Promote a user as a teacher
  In order to add teacher specific data to a user
  As a GDRP administrator
  I want to promote a user as a teacher

  Background:
    Given I am a GDPR administrator
    And there exists an additional user
    And I am logged in
    And I am on his user detail page

  Scenario: Successfully promote a teacher
    When I promote him to a teacher
    And I submit the teacher information
    And I visit his user detail page
    Then the user is a teacher
    And the user has his teacher information configured

  Scenario: Test fallback logic of teacher description
    Given an active course was created
    And the language is set to English
    When I promote him to a teacher
    And I only provide a German description
    And I visit the course edit page
    And I assign the additional user to the course as a teacher
    And I am on the course detail page
    Then I see the German description
