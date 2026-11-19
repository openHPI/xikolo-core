# frozen_string_literal: true

require 'spec_helper'

describe 'Global: Create a support ticket', type: :system do
  let(:user) { create(:'account_service/user') }

  it 'creates a ticket' do
    sign_in(user:)
    visit '/helpdesk'

    fill_in 'Title of your issue', with: 'I need help'
    fill_in 'Your Issue', with: 'Where do I find the certificados?'

    perform_enqueued_jobs do
      click_on 'Report issue'

      expect(page).to have_text 'Your request has been sent to our support team'
    end

    mail = find_mail_to('helpdesk@example.com')
    expect(mail).to have_attributes(subject: 'I need help')
    expect(mail.body.encoded).to include('Topic: technical')
    expect(mail.body.encoded).to include('certificados')
  end

  it 'creates a ticket as anonymous user' do
    visit '/helpdesk'

    fill_in 'Title of your issue', with: 'I need help'
    fill_in 'Your Issue', with: 'Where do I find the certificados?'

    fill_in 'Your e-mail address', with: 'hasso@plattner.de'

    perform_enqueued_jobs do
      click_on 'Report issue'

      expect(page).to have_text 'Your request has been sent to our support team'
    end

    mail = find_mail_to('helpdesk@example.com')
    expect(mail).to have_attributes(subject: 'I need help')
    expect(mail.body.encoded).to include('Topic: technical')
    expect(mail.body.encoded).to include('certificados')
  end

  it 'creates a ticket for a course' do
    course = create(:'course_service/course', :active)
    sign_in(user:)
    visit '/helpdesk'

    select course.title, from: 'Category'

    fill_in 'Title of your issue', with: 'I need help'
    fill_in 'Your Issue', with: 'Where do I find the certificados?'

    perform_enqueued_jobs do
      click_on 'Report issue'

      expect(page).to have_text 'Your request has been sent to our support team'
    end

    mail = find_mail_to('helpdesk@example.com')
    expect(mail).to have_attributes(subject: "#{course.course_code}: I need help")
    expect(mail.body.encoded).to include("Topic: course (#{course.id})")
    expect(mail.body.encoded).to include('certificados')
  end

  it 'creates a ticket with recaptcha enabled', :recaptcha_v3 do
    xi_config <<~YML
      recaptcha:
        enabled: true
        score: 0.5
        site_key_v2: 6Ld08WIqAAAAAMzWokw1WbhB2oY0LJRABkYC0Wrz
        site_key_v3: 6Lfz8GIqAAAAADuPSE0XXDa9XawEf0upsswLgsBA
    YML

    recaptcha_double = instance_double(Xi::Recaptcha::V3)
    allow(recaptcha_double).to receive(:verified?).and_return(true)
    allow(Xi::Recaptcha::V3).to receive(:new).and_return(recaptcha_double)

    sign_in(user:)
    visit '/helpdesk'

    fill_in 'Title of your issue', with: 'I need help'
    fill_in 'Your Issue', with: 'Where do I find the certificados?'

    perform_enqueued_jobs do
      click_on 'Report issue'

      expect(page).to have_text 'Your request has been sent to our support team'
    end

    mail = find_mail_to('helpdesk@example.com')
    expect(mail).to have_attributes(subject: 'I need help')
    expect(mail.body.encoded).to include('Topic: technical')
    expect(mail.body.encoded).to include('certificados')
  end

  it 'creates a ticket with recaptcha enabled that fails invisible recaptcha', :recaptcha_v2 do
    xi_config <<~YML
      recaptcha:
        enabled: true
        score: 0.5
        site_key_v2: 6Ld08WIqAAAAAMzWokw1WbhB2oY0LJRABkYC0Wrz
        site_key_v3: 6Lfz8GIqAAAAADuPSE0XXDa9XawEf0upsswLgsBA
    YML

    recaptcha_v3_double = instance_double(Xi::Recaptcha::V3)
    expect(recaptcha_v3_double).to receive(:verified?).and_return(false).twice
    allow(Xi::Recaptcha::V3).to receive(:new).and_return(recaptcha_v3_double)

    # Stub recaptcha v2 to fail first (no token), then succeed (with token)
    # On first submission, v2 should also fail because user hasn't clicked checkbox yet
    # On second submission, v2 should succeed
    recaptcha_v2_double = instance_double(Xi::Recaptcha::V2)
    expect(recaptcha_v2_double).to receive(:verified?).and_return(false, true)
    allow(Xi::Recaptcha::V2).to receive(:new).and_return(recaptcha_v2_double)

    sign_in(user:)
    visit '/helpdesk'

    fill_in 'Title of your issue', with: 'I need help'
    fill_in 'Your Issue', with: 'Where do I find the certificados?'

    # First submission fails both v3 and v2, should show checkbox
    click_on 'Report issue'

    expect(page).to have_text "Confirm you're human by checking the box below."

    expect(page).to have_field('Title of your issue', with: 'I need help')
    expect(page).to have_field('Your Issue', with: 'Where do I find the certificados?')

    # Submit again with v2 verification (now v2 will return true)
    perform_enqueued_jobs do
      click_on 'Report issue'

      expect(page).to have_text 'Your request has been sent to our support team'
    end

    mail = find_mail_to('helpdesk@example.com')
    expect(mail).to have_attributes(subject: 'I need help')
    expect(mail.body.encoded).to include('Topic: technical')
    expect(mail.body.encoded).to include('certificados')
  end
end
