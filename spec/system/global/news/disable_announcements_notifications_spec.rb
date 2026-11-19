# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: One click unsubscription of email announcements', type: :system do
  let(:user) { create(:'account_service/user', language: 'en') }

  before do
    user.update!(preferences: user.preferences.merge(
      'notification.email.global' => true
    ))

    NewsService::AnnouncementMailer.announcement(
      create(:'news_service/message'),
      user.as_json.merge('email' => user.email, 'language' => 'en')
    ).deliver_now
  end

  it 'uses disable link as logged in user' do
    sign_in(user: user)

    email = find_mail_to(user.email)
    disable_link_match = email.html_part.body.match(%r{href="([^"]+notification_user_settings/disable\?[^"]*key=announcement[^"]*)"})
    expect(disable_link_match).to be_present

    disable_link = CGI.unescapeHTML(disable_link_match[1])
    uri = Addressable::URI.parse(disable_link)
    visit "#{uri.path}?#{uri.query}"

    expect(page).to have_current_path('/preferences')
    expect(page).to have_text("Your account #{user.email} will not receive any more platform news.")

    user.reload
    expect(user.preferences['notification.email.news.announcement']).to eq('false')
  end
end
