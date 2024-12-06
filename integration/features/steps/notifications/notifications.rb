# frozen_string_literal: true

require 'pry'

module Steps
  module Notifications
    Then 'I receive an email notification' do
      user  = context.fetch :user
      mails = fetch_emails(to: user[:email])
      count = mails.count
      expect(count).to eq 1
    end

    Then 'I only have one mail' do
      user  = context.fetch :user
      mails = fetch_emails(to: user[:email])
      count = mails.count
      expect(count).to eq 1
    end

    Then 'there are no new mails' do
      context.with :user do |user|
        expect { fetch_emails to: user['email'], timeout: 15 }.to raise_error
      end
    end

    When 'I disable all global mail notifications' do
      send 'Given I am on the profile settings page'
      page.find('label', text: 'may send me notifications via e-mail').click
    end

    Then 'email notifications should be turned off' do
      context.with :user do |user|
        expect(page).to have_content "Your account #{user[:email]} will not receive any more notifications via email."
        send :'Given I am logged in'
        send :'Given I am on the profile settings page'
        expect(page.find('#preferences-notification-email-global', visible: false).value).to eq 'false'
      end
    end

    Then 'announcement notifications should be turned off' do
      context.with :user do |user|
        expect(page).to have_content "Your account #{user[:email]} will not receive any more platform news."
        send :'Given I am logged in'
        send :'Given I am on the profile settings page'
        expect(page.find('#preferences-notification-email-news-announcement', visible: false).value).to eq 'false'
      end
    end

    Then 'forum notifications should be turned off' do
      context.with :user do |user|
        expect(page).to have_content "Your account #{user[:email]} will not receive any more pinboard news."
        send :'Given I am logged in'
        send :'Given I am on the profile settings page'
        expect(page.find('#preferences-notification-email-pinboard-new-answer', visible: false).value).to eq 'false'
      end
    end

    Then 'email notifications should not be turned off' do
      expect(page).to have_notice 'The provided link seems to be invalid.'
      send :'Given I am logged in'
      send :'Given I am on the profile settings page'
      expect(page.find('#preferences-notification-email-global', visible: false).value).to eq 'true'
    end
  end
end

Gurke.configure do |c|
  c.include Steps::Notifications
end
