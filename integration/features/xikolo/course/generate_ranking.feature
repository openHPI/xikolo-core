@xi-1068 @implemented
Feature: Administrator generates course ranking
  In order to create records after course completion
  As an administrator
  I should be able to generate course ranking.

  Background:
    Given an active course was created
    And I am logged in as a course admin
    And there exist some users
    And I am on the course edit page

  Scenario: Generate ranking
    When I generate the course ranking
    Then the course ranking is being generated
