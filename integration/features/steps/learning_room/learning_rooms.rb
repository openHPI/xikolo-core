# frozen_string_literal: true

module Steps
  module LearningRoom
    Then 'the collab space should be marked as team' do
      context.with :learning_room do |team|
        expect(page).to have_content "Team: #{team['name']}"
      end
    end

    Then 'I should not be able to join' do
      expect(page).to_not have_content 'Request membership'
    end

    Then 'I should be listed as admin' do
      context.with :user do |user|
        expect(page).to have_content "#{user['name']} (Admin)"
      end
    end

    Then 'I should not be able to leave the team' do
      expect(page).to_not have_content 'Quit my membership'
    end

    Then 'I should not be able to manage members' do
      expect(page).to_not have_content 'Membership management'
    end

    Then 'I should not be able to delete the collab space' do
      expect(page).to_not have_content 'Delete Collab Space'
    end

    Then 'I can change the collab space name' do
      expect(page).to have_selector '#collabspace_name'
    end

    When 'I remove the team member' do
      click_on 'Remove member'
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    Then 'the member should not be listed' do
      context.with :team_member do |member|
        expect(page).to_not have_content member
      end
    end

    Then 'I should be listed in the member list' do
      context.with :user do |user|
        expect(page).to have_content user['name']
      end
    end

    When 'I select a user from the list' do
      context.with :users do |users|
        tom_select users.first['email'], from: 'User', search: true
      end
    end

    When(/^I mark the member as (\w+)$/) do |status|
      select status, from: 'xikolo_collabspace_membership_status'
    end

    When 'I create the membership' do
      click_on 'Create Membership'
    end

    Then(/^the member should be listed as (\w+)$/) do |status|
      context.with :users do |users|
        expect(page).to have_content "#{users.first['name']} (#{status})"
      end
    end

    When 'I join the collab space' do
      click_on 'Join Collab Space'
    end

    When 'I request membership to the collab space' do
      click_on 'Request membership'
    end

    Then 'my membership should be pending' do
      expect(page).to have_content 'You are currently waiting for your membership status to be approved.'
    end
  end
end

Gurke.config.include Steps::LearningRoom
