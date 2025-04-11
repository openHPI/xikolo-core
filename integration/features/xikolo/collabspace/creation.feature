Feature: A Learning Room is created

  Background:
    Given a basic course setup exists
    And I am on the course detail page

  Scenario:
    When I create a Learning Room
    Then I should see the Learning Room in the list
