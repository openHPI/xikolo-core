Feature: Find user email address
  In order to contact a user having an issue
  As a teacher
  I have to see the user's email address on his profile page.

  Scenario: As a admin (later to be: teacher) show me the email address
    Given I am a GDPR administrator
    # Alternative, but not not working yet, because navigation on last step relies on the Admin menu
    # Given I am logged in as a course admin
    And there exists an additional user
    And an active course was created
    And I am logged in
    And I am on his user detail page
    Then I see the additional user's primary email address

  # Not working yet, because navigation needs Admin menu
 # Scenario: As a normal user do not show me the email address
 #   Given an active course was created
 #   And I am confirmed, enrolled and logged in
 #   And there exists an additional user
 #   Then I do not see the additional user's primary email address
