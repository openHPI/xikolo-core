@xi-1139
Feature:  Show news ordered by newest first
  In order to show current news
  As a visitor
  I should see the news ordered by their publishing date

  Background:
  Given I am an administrator
  And I am logged in

  @feature:announcements
  Scenario: Show news ordered by publishing date
    When I write 5 global news with visual
    And I am on the news page
    Then the 5 news should be ordered by their publishing date
    And the tog-wrapper should be ordered by publishing date
