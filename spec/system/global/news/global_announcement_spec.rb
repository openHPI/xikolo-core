# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: Publish a global announcement', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    sign_in(user: admin)
    click_on 'News'
  end

  it 'creates a global announcement' do
    click_on 'Create new announcement'

    fill_in 'announcement[title]', with: 'Test Title'
    fill_in 'Publish at', with: 2.days.ago.iso8601
    fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'

    click_on 'Save'

    expect(page).to have_text 'Test Title'
  end

  it 'receives a test email' do
    additional_user = create(:'account_service/user', full_name: 'Jane Austen', display_name: 'Jane Austen')
    additional_user.update!(preferences: additional_user.preferences.merge(
      'notification.email.global' => true
    ))

    click_on 'Create new announcement'

    fill_in 'announcement[title]', with: 'Test Title'
    fill_in 'Publish at', with: 2.days.ago.iso8601
    fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'

    perform_enqueued_jobs do
      click_on 'Save and send test mail'
      expect(page).to have_text 'Test Title'
    end

    mail = find_mail_to(admin.email)
    expect(mail).to have_attributes(subject: start_with('Test Title'))
    expect(mail.body.encoded).to include('Test Title', 'Test text', 'This is a test message, only you received this!')

    expect(find_mail_to(additional_user.email)).to be_nil
  end

  it 'has save and send button disabled by default' do
    click_on 'Create new announcement'

    expect(page).to have_button 'Save and send', disabled: true, exact: true
  end

  it 'enables save and send button and sends' do
    click_on 'Create new announcement'

    fill_in 'announcement[title]', with: 'Test Title'
    fill_in 'Publish at', with: 2.days.ago.iso8601
    fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'

    page.find(:xpath, "//label[contains(@for, 'enable-save-send')]").click

    perform_enqueued_jobs do
      click_on 'Save and send', exact: true
      expect(page).to have_text 'Test Title'
    end
  end

  it 'sends announcement email to all users' do
    additional_user = create(:'account_service/user', full_name: 'Jane Austen', display_name: 'Jane Austen')
    additional_user.update!(preferences: additional_user.preferences.merge(
      'notification.email.global' => true
    ))

    admin.update!(preferences: admin.preferences.merge(
      'notification.email.global' => true
    ))

    click_on 'Create new announcement'

    fill_in 'announcement[title]', with: 'Test Title'
    fill_in 'Publish at', with: 2.days.ago.iso8601
    fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'

    page.find(:xpath, "//label[contains(@for, 'enable-save-send')]").click

    perform_enqueued_jobs do
      click_on 'Save and send', exact: true
      expect(page).to have_text 'Test Title'
    end

    expect(find_mail_to(admin.email).body.encoded).to include('Test Title', 'Test text')
    expect(find_mail_to(additional_user.email).body.encoded).to include('Test Title', 'Test text')
  end
end
