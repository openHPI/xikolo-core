# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Course subscriptions trigger notifications', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }
  let(:other_user) { create(:'account_service/user') }

  it 'receives notification email for new topic after subscribing to course' do
    sign_in(user:)
    enroll_in(course)

    click_on 'Forum'
    click_on 'Follow discussion forum'
    wait_for_turbo_idle

    find('[aria-label="Profile menu"]').click
    click_on 'Log out'

    sign_in(user: other_user)
    enroll_in(course)

    click_on 'Forum'
    click_on 'Start a new topic'
    fill_in 'Title', with: 'New Topic'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'Body'

    perform_enqueued_jobs do
      click_on 'Post new topic'
      expect(page).to have_text 'New Topic'
      sleep 0.2 # wait for custom Ajax
    end

    mail = find_mail_to(user.email)
    expect(mail.subject).to include('There is a new topic in the forum.')
    expect(mail.html_part.body.to_s).to include('Discussion Forum Activity')
    expect(mail.html_part.body.to_s).to include('posted in the forum')
    expect(mail.html_part.body.to_s).to include('Body')
  end

  it 'does not receive notification after unsubscribing from course' do
    sign_in(user:)
    enroll_in(course)

    click_on 'Forum'
    click_on 'Follow discussion forum'
    wait_for_turbo_idle
    click_on 'Unfollow discussion forum'
    wait_for_turbo_idle

    find('[aria-label="Profile menu"]').click
    click_on 'Log out'

    sign_in(user: other_user)
    enroll_in(course)

    click_on 'Forum'
    click_on 'Start a new topic'
    fill_in 'Title', with: 'New Topic'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'Body'

    perform_enqueued_jobs do
      click_on 'Post new topic'
      expect(page).to have_text 'New Topic'
      sleep 0.2 # wait for custom Ajax
    end

    expect(find_mail_to(user.email)).to be_nil
  end
end
