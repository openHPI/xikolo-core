# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: Publish an announcement via email', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    sign_in(user: admin)
  end

  describe 'Draft an announcement' do
    it 'creates a targeted announcement and shows publish button' do
      click_on 'Administration'
      within '[data-behaviour="menu-dropdown"]' do
        click_on 'Announcements'
      end

      click_on 'Draft new announcement'

      within_fieldset('English') do
        fill_in 'Subject', with: 'Join our new course on MOOCs!'
        fill_markdown_editor 'Content', with: 'You already took our first course - now join the second one.'
      end

      within_fieldset('German') do
        fill_in 'Subject', with: 'Besuchen Sie unseren neuen Kurs über MOOCs!'
        fill_markdown_editor 'Content',
          with: 'Sie haben bereits unseren ersten Kurs abgeschlossen - besuchen Sie jetzt den zweiten.'
      end

      click_on 'Create announcement'

      expect(page).to have_text 'Join our new course on MOOCs!'
      expect(page).to have_text 'Edit for publishing'
    end
  end

  describe 'Send out a test mail' do
    let!(:additional_user) { create(:'account_service/user', full_name: 'Jane Austen', display_name: 'Jane Austen') }

    before do
      create(:'account_service/treatment', name: 'marketing')
      create(:'news_service/announcement',
        author_id: admin.id,
        translations: {
          'en' => {
            'subject' => 'Join our new course on MOOCs!',
            'content' => 'You already took our first course - now join the second one.',
          },
        })
    end

    it 'sends test email to selected user only' do
      visit '/admin/announcements'

      click_on 'Edit for publishing'

      tom_select admin.name, from: 'Recipients', search: admin.email

      find('label', text: 'Send as test email').click

      perform_enqueued_jobs do
        click_on 'Send announcement email'
        click_on 'Yes, sure'

        expect(page).to have_text 'Join our new course on MOOCs!'
      end

      mail = find_mail_to(admin.email)
      expect(mail).to have_attributes(
        subject: start_with('Join our new course on MOOCs!')
      )
      expect(mail.body.encoded).to include(
        'This is a test message, only you received this!',
        'You already took our first course - now join the second one.'
      )
      expect(find_mail_to(additional_user.email)).to be_nil
    end
  end

  describe 'Send out the final email without consents' do
    let(:course) { create(:'course_service/course', :active) }
    let!(:additional_user) { create(:'account_service/user', full_name: 'Jane Austen', display_name: 'Jane Austen') }

    before do
      create(:'account_service/treatment', name: 'marketing')

      visit current_path
      check('consent_marketing', allow_label_click: true)
      click_on('Proceed')

      enroll_in(course)

      additional_user_group = AccountService::Group.find_by!(name: "course.#{course.course_code}.students")
      create(:'account_service/membership', user: additional_user, group: additional_user_group)

      create(:'news_service/announcement',
        author_id: admin.id,
        translations: {
          'en' => {
            'subject' => 'Join our new course on MOOCs!',
            'content' => 'You already took our first course - now join the second one.',
          },
        })
    end

    it 'sends announcement email to all enrolled users' do
      visit '/admin/announcements'

      click_on 'Edit for publishing'

      tom_select course.course_code, from: 'Recipients', search: true

      perform_enqueued_jobs do
        click_on 'Send announcement email'
        click_on 'Yes, sure'

        expect(page).to have_text 'Join our new course on MOOCs!'
      end

      expect(find_mail_to(admin.email).body.encoded).to include(
        'You already took our first course - now join the second one.'
      )
      expect(find_mail_to(additional_user.email).body.encoded).to include(
        'You already took our first course - now join the second one.'
      )
    end
  end

  describe 'Send out the final email to only consented users' do
    let(:course) { create(:'course_service/course', :active) }
    let!(:additional_user) { create(:'account_service/user', full_name: 'Jane Austen', display_name: 'Jane Austen') }

    before do
      create(:'account_service/treatment', name: 'marketing')
      visit current_path
      check('consent_marketing', allow_label_click: true)
      click_on('Proceed')

      enroll_in(course)

      additional_user_group = AccountService::Group.find_by!(name: "course.#{course.course_code}.students")
      create(:'account_service/membership', user: additional_user, group: additional_user_group)

      create(:'news_service/announcement',
        author_id: admin.id,
        translations: {
          'en' => {
            'subject' => 'Join our new course on MOOCs!',
            'content' => 'You already took our first course - now join the second one.',
          },
        })
    end

    it 'sends announcement email only to users with consent' do
      visit '/admin/announcements'

      click_on 'Edit for publishing'

      tom_select course.course_code, from: 'Recipients', search: true
      tom_select 'marketing', from: 'Consents'

      perform_enqueued_jobs do
        click_on 'Send announcement email'
        click_on 'Yes, sure'

        expect(page).to have_text 'Join our new course on MOOCs!'
      end

      expect(find_mail_to(admin.email)).to have_attributes(
        subject: start_with('Join our new course on MOOCs!')
      )
      expect(find_mail_to(admin.email).body.encoded).to include(
        'You already took our first course - now join the second one.'
      )
      expect(find_mail_to(additional_user.email)).to be_nil
    end
  end
end
