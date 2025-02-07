# frozen_string_literal: true

module Steps
  module Helpdesk
    Given 'recaptcha is enabled' do
      set_xikolo_config('recaptcha',
        enabled: true,
        score: 0.5,
        site_key_v2: '6Ld08WIqAAAAAMzWokw1WbhB2oY0LJRABkYC0Wrz',
        site_key_v3: '6Lfz8GIqAAAAADuPSE0XXDa9XawEf0upsswLgsBA')
      set_xikolo_config('csp',
        frame: ['https://www.recaptcha.net'],
        script: ['https://www.recaptcha.net', 'https://www.gstatic.com'])
    end

    When 'I open the helpdesk' do
      page.find('#helpdesk-button').click
    end

    When 'I follow the link to the helpdesk' do
      click_on 'Go to helpdesk'
    end

    When 'I describe my issue in detail' do
      fill_in 'Title of your issue', with: 'I need help'
      fill_in 'Your Issue', with: 'Where do I find the certificados?'
    end

    When 'recaptcha is ready' do
      input = find('input#g-recaptcha-response-data-helpdesk', visible: :hidden)
      Test.wait(max: 30) do
        expect(input.value).to match(/\S/)
      end
    end

    When 'I provide an e-mail address' do
      fill_in 'Your e-mail address', with: 'hasso@plattner.de'
    end

    When 'I select the course as ticket category' do
      context.with :course do |course|
        select course['title'], from: 'Category'
      end
    end

    When 'I submit the ticket' do
      click_on 'Report issue'
    end

    Then 'I confirm I am not a robot' do
      recaptcha_v2_iframe = find('div[data-sitekey="6Ld08WIqAAAAAMzWokw1WbhB2oY0LJRABkYC0Wrz"] iframe')
      within_frame(recaptcha_v2_iframe) do
        find('label', text: "I'm not a robot").click
      end
    end

    Then 'I pass the challenge' do
      # grecaptcha.getResponse() triggers Google's reCAPTCHA client-side JavaScript library, which returns a token
      # when the reCAPTCHA v2 challenge is passed.
      recaptcha_token = '329iorjwea' * 20
      page.execute_script(
        "window.grecaptcha = { getResponse: function() { return \"#{recaptcha_token}\"; } };"
      )
    end

    Then 'the course should be listed in the category menu' do
      context.with :course do |course|
        expect(page).to have_select 'Category', with_options: [course['title']]
      end
    end

    Then 'the course should be pre-selected in the category menu' do
      context.with :course do |course|
        expect(page).to have_select 'Category', selected: course['title']
      end
    end

    Then 'I should be notified about successful ticket submission' do
      expect(page).to have_content 'Your request has been sent to our support team'
    end

    Then 'I should be asked to identify myself as a human' do
      assert_text("Confirm you're human by checking the box below.")
    end

    Then 'an email with my report should be sent to the helpdesk software' do
      open_email fetch_emails(
        to: 'helpdesk@example.com',
        subject: 'I need help'
      ).first

      expect(page).to have_content 'Topic: technical'
      expect(page).to have_content 'certificados'
    end

    Then 'an email with my course-specific report should be sent to the helpdesk software' do
      course = context.fetch(:course)

      open_email fetch_emails(
        to: 'helpdesk@example.com',
        subject: "#{course['course_code']}: I need help"
      ).first

      expect(page).to have_content "Topic: course (#{course['id']})"
      expect(page).to have_content 'certificados'
    end
  end
end

Gurke.configure {|c| c.include Steps::Helpdesk }
