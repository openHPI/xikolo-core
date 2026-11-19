# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Announcement: Create Email', type: :system do
  let(:user) { create(:'account_service/user', :gdpr_admin) }
  let(:some_course) { create(:course, course_code: 'some-course') }
  let(:cloud2013) { create(:course, course_code: 'cloud2013') }
  let(:another_course) { create(:course, course_code: 'another-course', title: 'Another Course') }
  let(:announcement_id) { SecureRandom.uuid }
  let(:recipients) { [] }
  let(:announcement) do
    create(:'news_service/announcement',
      id: announcement_id,
      translations: {'en' => {
        'subject' => 'This might interest you',
        'content' => 'Check it out!',
      }},
      recipients:,
      author_id: user.id,
      created_at: 1.day.ago)
  end

  before do
    sign_in(user:)

    announcement
    some_course
    another_course
    cloud2013

    create(:'account_service/treatment', name: 'marketing')
    create(:'account_service/group', name: 'announcement.recipients.custom', tags: ['custom_recipients'])
  end

  it 'prefills, adjusts, and publishes the email announcement' do
    visit "/admin/announcements/#{announcement_id}/email/new"

    within_fieldset('English') do
      expect(page).to have_field('Subject', with: 'This might interest you')
      expect(page).to have_markdown_editor('Content', with: 'Check it out!')
    end

    within_fieldset('English') do
      fill_in 'Subject', with: 'News: This might interest you'
      fill_markdown_editor 'Content', with: 'Dear users, please check it out!'
    end
    tom_select user.name, from: 'Recipients', search: true
    tom_select 'some-course', from: 'Recipients', search: true
    tom_select 'Another Course', from: 'Recipients', search: true
    tom_select 'Affiliated users', from: 'Recipients', search: true
    tom_select 'Students of course', from: 'Recipients', search: 'cloud2013'
    tom_select 'announcement.recipients.custom', from: 'Recipients', search: 'custom'
    tom_select 'marketing', from: 'Consents'

    click_link_or_button 'Send announcement email'
    click_link_or_button 'Yes, sure'

    # Since there is no flash message when an announcement has been
    # created, we check that the new announcement is visible on the page
    # (listed under "Published").
    expect(page).to have_text 'This might interest you'
    expect(page).to have_text 'There are currently no announcement drafts.'
  end

  context 'with predefined recipients' do
    let(:recipients) {
      [
        "urn:x-xikolo:account:user:#{user.id}",
        'urn:x-xikolo:account:group:some.group.1',
        'urn:x-xikolo:account:group:course.another-course.students',
      ]
    }

    before do
      create(:'account_service/group', name: 'some.group.1', tags: ['custom_recipients'])
      create(:'account_service/group', name: 'course.another-course.students', tags: ['custom_recipients'])
    end

    it 'prefills, adjusts, and publishes the email announcement' do
      visit "/admin/announcements/#{announcement_id}/email/new"

      within_fieldset('English') do
        expect(page).to have_field('Subject', with: 'This might interest you')
        expect(page).to have_markdown_editor('Content', with: 'Check it out!')
      end

      within_fieldset('English') do
        fill_in 'Subject', with: 'News: This might interest you'
        fill_markdown_editor 'Content', with: 'Dear users, please check it out!'
      end
      tom_select 'some-course', from: 'Recipients', search: true
      tom_select 'marketing', from: 'Consents'

      click_link_or_button 'Send announcement email'
      click_link_or_button 'Yes, sure'

      # Since there is no flash message when an announcement has been
      # sent out, we check that the (original) announcement is still visible
      # on the page (listed under "Published").
      expect(page).to have_text 'This might interest you'
      expect(page).to have_text 'There are currently no announcement drafts.'
    end
  end

  it 'publishes a test email announcement' do
    visit "/admin/announcements/#{announcement_id}/email/new"

    within_fieldset('English') do
      expect(page).to have_field('Subject', with: 'This might interest you')
      expect(page).to have_markdown_editor('Content', with: 'Check it out!')
    end

    tom_select user.name, from: 'Recipients', search: true
    find('label', text: 'Send as test email').click

    click_link_or_button 'Send announcement email'
    click_link_or_button 'Yes, sure'

    # Since there is no flash message when a test announcement has been
    # sent out, we check that the announcement is visible on the page
    # (listed under "Draft").
    expect(page).to have_text 'This might interest you'
    expect(page).to have_no_text 'There are currently no announcement drafts.'
  end
end
