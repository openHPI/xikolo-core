@feature:admin_announcements
Feature: Publish an announcement via email
  In order to reach specific target groups with news and announcements
  As a marketing team member
  I want to send emails to specific users and user groups

  Background:
    Given there is a marketing treatment
    And I am an administrator
    And I am logged in

  Scenario: Draft an announcement
    When I go to the admin announcements list
    And I draft a new targeted announcement
    And I fill out the targeted announcement fields
    And I save the targeted announcement
    Then I should be on the admin announcements list
    And I see a button to publish the new announcement via email

  Scenario: Send out a test mail
    Given there exists an additional user
    And a targeted announcement was created
    And I am on the admin announcements list
    When I edit the announcement for publishing via email
    And I select a user as the recipient
    And I publish the announcement as test email
    Then I should receive a test email with the content inherited from the announcement
    And the additional user should not receive a targeted announcement mail

  Scenario: Send out the final email without consents
    Given an active course was created
    And I am enrolled in the course
    And there exists an additional user
    And the additional user is enrolled
    And a targeted announcement was created
    And I am on the admin announcements list
    When I edit the announcement for publishing via email
    And I select course students as the recipients
    And I publish the announcement
    Then all users should receive a targeted announcement email

  Scenario: Send out the final email to only consented users
    Given an active course was created
    And I am enrolled in the course
    And I consented to marketing
    And there exists an additional user
    And the additional user is enrolled
    And a targeted announcement was created
    And I am on the admin announcements list
    When I edit the announcement for publishing via email
    And I select course students as the recipients
    And I require users to consent to marketing
    And I publish the announcement
    Then only users who have given consent to marketing receive an email
