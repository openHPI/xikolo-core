Feature: Administrator creates document
  In order to enable teachers to distribute wisdom amongst the masses
  As an administrator
  I should be able to create a new document.

  Background:
    Given I am an administrator
    And I am logged in
    And I am on the documents admin page

  Scenario: Create a document
    When I navigate to the document creation page
    And I fill in the document data
    And I submit the document data
    Then This document exists
    And There is a download link for the document

    When I click on add a new localization
    And I fill in the localization data
    And I submit the localization data
    And I click on add a new localization
    And I fill in the localization data for another language
    And I submit the localization data
    Then the three localizations are shown

