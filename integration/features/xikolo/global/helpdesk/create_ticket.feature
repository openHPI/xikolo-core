Feature: Create a support ticket using the helpdesk
  In order to get help using the platform
  as a user
  I want to send an email to the support team via the helpdesk

  Scenario: Create a ticket
    Given I am logged in as a confirmed user
    And I am on the homepage
    When I open the helpdesk
    And I describe my issue in detail
    And I submit the ticket
    Then I should be notified about successful ticket submission
    And an email with my report should be sent to the helpdesk software

  Scenario: Create a ticket as anonymous user
    Given I am on the homepage
    When I open the helpdesk
    And I describe my issue in detail
    And I provide an e-mail address
    And I submit the ticket
    Then I should be notified about successful ticket submission
    And an email with my report should be sent to the helpdesk software

  Scenario: Create a ticket for a course
    Given I am logged in as a confirmed user
    And an active course was created
    And I am on the homepage
    When I open the helpdesk
    And I select the course as ticket category
    And I describe my issue in detail
    And I submit the ticket
    Then I should be notified about successful ticket submission
    And an email with my course-specific report should be sent to the helpdesk software

  Scenario: Create a ticket after encountering an error
    Given I am logged in as a confirmed user
    And I am on a page that does not exist
    When I follow the link to the helpdesk
    And I describe my issue in detail
    And I submit the ticket
    Then I should be notified about successful ticket submission
    And an email with my report should be sent to the helpdesk software

  Scenario: Create a ticket after encountering an error as anonymous user
    Given I am on a page that does not exist
    When I follow the link to the helpdesk
    And I describe my issue in detail
    And I provide an e-mail address
    And I submit the ticket
    Then I should be notified about successful ticket submission
    And an email with my report should be sent to the helpdesk software

  @wip
  @recaptcha_v3
  Scenario: Create a ticket with recaptcha enabled
    Given I am logged in as a confirmed user
    And recaptcha is enabled
    And I am on the homepage
    When I open the helpdesk
    And I describe my issue in detail
    And recaptcha is ready
    And I submit the ticket
    Then I should be notified about successful ticket submission
    And an email with my report should be sent to the helpdesk software

  @wip
  @recaptcha_v2
  Scenario: Create a ticket with recaptcha enabled that fails invisible recaptcha
    Given I am logged in as a confirmed user
    And recaptcha is enabled
    And I am on the homepage
    When I open the helpdesk
    And I describe my issue in detail
    And recaptcha is ready
    And I submit the ticket
    Then I should be asked to identify myself as a human
    And I confirm I am not a robot
    And I pass the challenge
    When I submit the ticket
    Then I should be notified about successful ticket submission
    And an email with my report should be sent to the helpdesk software
