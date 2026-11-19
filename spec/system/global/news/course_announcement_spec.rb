# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: Publish a course announcement', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }

  before do
    course

    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group:)

    sign_in(user:)
    enroll_in(course)
  end

  it 'creates a course announcement' do
    click_on 'Announcements'
    click_on 'Add new course announcement'

    fill_in 'Title', with: 'Test Title'
    fill_in 'Publish at', with: 2.days.ago.iso8601
    fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'

    click_on 'Save'

    expect(page).to have_text 'Test Title'
  end

  it 'receives a test email' do
    additional_user = create(:'account_service/user')
    create(:'course_service/enrollment', course: course, user_id: additional_user.id)

    click_on 'Announcements'
    click_on 'Add new course announcement'

    fill_in 'Title', with: 'Test Title'
    fill_in 'Publish at', with: 2.days.ago.iso8601
    fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'

    perform_enqueued_jobs do
      click_on 'Save and send test mail'
      # Wait for the form to be processed and redirect to the announcements list
      expect(page).to have_current_path(%r{learn/#{course.course_code}/announcements$})
    end

    expect(find_mail_to(user.email)).to have_attributes(subject: start_with('Test Title: '))
    expect(find_mail_to(user.email).body.encoded).to include('Test Title', 'Test text', 'This is a test message, only you received this!')
    expect(find_mail_to(additional_user.email)).to be_nil
  end

  it 'receives an email' do
    additional_user = create(:'account_service/user')
    create(:'course_service/enrollment', course: course, user_id: additional_user.id)

    unenrolled_user = create(:'account_service/user')

    click_on 'Announcements'
    click_on 'Add new course announcement'

    fill_in 'Title', with: 'Test Title'
    fill_in 'Publish at', with: 2.days.ago.iso8601
    fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'

    # Enable the "Save and send" button via its toggle checkbox
    page.find("label[for='enable-save-send']").click

    perform_enqueued_jobs do
      click_on 'Save and send'
      # Wait for the form to be processed and redirect to the announcements list
      expect(page).to have_current_path(%r{learn/#{course.course_code}/announcements$})
    end

    expect(find_mail_to(user.email)).to have_attributes(subject: start_with('Test Title: '))
    expect(find_mail_to(user.email).body.encoded).to include('Test Title', 'Test text')
    expect(find_mail_to(additional_user.email)).to have_attributes(subject: start_with('Test Title: '))
    expect(find_mail_to(additional_user.email).body.encoded).to include('Test Title', 'Test text')
    expect(find_mail_to(unenrolled_user.email)).to be_nil
  end
end
