# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: One click unsubscription of forum notifications', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:'course_service/course', :active) }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: user.id) }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  it 'uses disable link as logged in user' do
    create(:'pinboard_service/subscription', question: question, user_id: user.id)
    answer_user = create(:'account_service/user')

    find('[aria-label="Profile menu"]').click
    expect(page).to have_css('[aria-label="Profile menu"][aria-expanded="true"]')
    click_on 'Log out'
    sign_in(user: answer_user)
    enroll_in(course)
    click_on 'Forum'
    click_on question.title

    fill_markdown_editor '#markdown-input-text-answer-', use_selector: true, with: 'Answer text'

    perform_enqueued_jobs do
      click_on 'Post reply'
      expect(page).to have_text('Answer text')
      wait_for_turbo_idle
    end

    find('[aria-label="Profile menu"]').click
    expect(page).to have_css('[aria-label="Profile menu"][aria-expanded="true"]')
    click_on 'Log out'

    sign_in(user: user)
    email = find_mail_to(user.email)

    doc = Nokogiri::HTML(email.html_part.body.to_s)
    disable_link = doc.at_css('a[href*="notification_user_settings/disable"]')['href']
    expect(disable_link).to be_present, 'Could not find disable link in email'

    disable_link = CGI.unescapeHTML(disable_link)
    uri = Addressable::URI.parse(disable_link)
    visit "#{uri.path}?#{uri.query}"

    expect(page).to have_current_path('/preferences')
    expect(page).to have_text("Your account #{user.email} will not receive any more pinboard news.")
  end
end
