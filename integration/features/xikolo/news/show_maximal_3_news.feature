@xi-814
Feature:  Show 3 news at a max
  In order to show the latest news
  As a visitor
  I should only be able to see 3 news at a max

  Background:
  Given I am an administrator
  And I am logged in

  @feature:announcements
  Scenario: Show only 3 news
    When I write 5 global news with visual
    And I log out
    And I am on the homepage
    Then there are the 3 latest news
