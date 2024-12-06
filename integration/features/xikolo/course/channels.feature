Feature: Course Channels
  In order to have dedicated landing pages
  As a platform
  I want to group courses into channels

  Background:
    Given an active course was created

  Scenario: Channel navigation
    Given a public channel was created
    And the course belongs to the channel
    When I am on the homepage
    Then I should see a dropdown labeled "Channels"
    When I click on the "Channels" dropdown
    Then I should see the channel name in the dropdown
    When I click on the channel name
    Then I should be on the channel's page
    And the course should be listed

  Scenario: Hidden channel navigation
    Given a private channel was created
    When I am on the homepage
    Then I should not see a dropdown labeled "Channels" in the platform navigation

  @feature:course_list
  Scenario: Hidden channel filter on the course page
    Given a private channel was created
    When I am on the course list
    Then I should not see a dropdown labeled "Channel" in the course filter bar
