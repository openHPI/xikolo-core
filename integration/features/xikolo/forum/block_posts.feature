Feature: Block a post
  In order to avoid abuse in the forum
  As an admin
  I want to block inappropriate behavior

  Background:
    Given an active course was created
    And a topic is posted in the general forum

  Scenario: Blocking a topic with abuse reports
    When three students report the topic
    Then the topic should be blocked

  Scenario: Blocking a topic directly
    Given I am logged in as admin
    And I am on the topic page
    When I block the topic
    Then the topic should be blocked

  Scenario: Sending an email when a topic is autoblocked
    Given there are two course admins
    When three students report the topic
    Then an email should be sent to all course admins
    And the link in the email should refer to the topic

  Scenario: An authorized user can still see or answer a blocked post
    Given I am logged in as admin
    And I am on the topic page
    And the topic has an answer
    When I block the topic
    Then I can see the topic's content
    And I can answer the topic
    And I can comment the answer

  Scenario: A normal user can't see or answer a blocked post
    Given I am confirmed, enrolled and logged in
    And the topic has an answer
    When the topic was blocked
    Then I can't see the topic's content
    And I can't answer the topic
