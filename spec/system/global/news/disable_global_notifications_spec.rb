# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: One click unsubscription of email notifications', type: :system do
  let(:user) { create(:'account_service/user', language: 'en') }
  let(:message) { create(:'news_service/message') }

  before do
    user.update!(preferences: user.preferences.merge(
      'notification.email.global' => true,
      'notification.email.news.announcement' => true
    ))
  end

  it 'uses disable link as logged in user' do
    sign_in(user: user)

    # Trigger sending an announcement message
    NewsService::AnnouncementMailer.announcement(message, user.as_json.merge('email' => user.email, 'language' => 'en')).deliver_now

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(user.email)

    body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    disable_link_match = body.match(%r{href="([^"]+notification_user_settings/disable\?[^"]*key=global[^"]*)"})
    expect(disable_link_match).to be_present

    disable_link = CGI.unescapeHTML(disable_link_match[1])
    uri = Addressable::URI.parse(disable_link)

    visit "#{uri.path}?#{uri.query}"

    expect(page).to have_current_path('/preferences')
    expect(page).to have_text("Your account #{user.email} will not receive any more notifications via email.")

    user.reload
    expect(user.preferences['notification.email.global']).to eq('false')
  end

  it 'uses disable link while being logged out' do
    NewsService::AnnouncementMailer.announcement(message, user.as_json.merge('email' => user.email, 'language' => 'en')).deliver_now

    email = ActionMailer::Base.deliveries.last

    body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    disable_link_match = body.match(%r{href="([^"]+notification_user_settings/disable\?[^"]*key=global[^"]*)"})
    expect(disable_link_match).to be_present

    disable_link = CGI.unescapeHTML(disable_link_match[1])
    uri = Addressable::URI.parse(disable_link)

    visit "#{uri.path}?#{uri.query}"

    expect(page).to have_current_path('/')
    expect(page).to have_text("Your account #{user.email} will not receive any more notifications via email.")

    user.reload
    expect(user.preferences['notification.email.global']).to eq('false')
  end

  it 'uses a disable link with invalid email address' do
    visit '/notification_user_settings/disable?email=foo.bar@nonsense.com&hash=nonsense&key=nonsense'

    expect(page).to have_current_path('/')
    expect(page).to have_text('The provided link seems to be invalid.')
  end

  it 'uses a disable link with invalid hash' do
    visit "/notification_user_settings/disable?email=#{user.email}&hash=nonsense&key=nonsense"

    expect(page).to have_current_path('/')
    expect(page).to have_text('The provided link seems to be invalid.')
  end
end
