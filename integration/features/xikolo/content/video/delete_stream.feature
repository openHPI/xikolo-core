Feature: Admin deletes a stream
  In order to remove duplicates
  As an admin
  I want to delete streams.

  Background:
    Given I am an administrator
    And I am logged in
    And I am on the video list page

  Scenario: delete a stream
    Given the pip stream is listed
    When I delete the pip stream
    Then the pip stream is not listed any more
