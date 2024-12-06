# frozen_string_literal: true

module Steps
  module News
    When 'I write a global news with visual' do
      visit '/news/new'
      fill_in 'announcement[title]', with: 'Global News Headline'
      fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'To Be, Or *Not* To Be'
      fill_in 'Publish at', with: 2.days.ago.iso8601
      attach_file 'Visual', asset_path('redsandsforts.jpg')
      click_on 'Save'

      # Wait for overview page after submit
      page.has_content? "Global News Headline #{i}"
    end

    When 'I write 5 global news with visual' do
      (1..5).each do |i|
        visit '/news/new'
        fill_in 'announcement[title]', with: "Global News Headline #{i}"
        fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'To Be, Or *Not* To Be'
        fill_in 'Publish at', with: i.days.ago.iso8601
        attach_file 'Visual', asset_path('profile_image.jpg')
        click_on 'Save'

        # Wait for overview page after submit
        page.has_content? "Global News Headline #{i}"
      end
    end

    Then 'there are the 3 latest news' do
      (1..3).each do |i|
        expect(page).to have_content "Global News Headline #{i}"
      end
      expect(page).to_not have_content 'Global News Headline 4'
    end

    Then 'the 5 news should be ordered by their publishing date' do
      newsitems = all('.news_item')
      (1..5).each do |i|
        expect(newsitems[i - 1].find('h3').text).to eq("Global News Headline #{i}")
      end
    end

    Then 'the tog-wrapper should be ordered by publishing date' do
      newsnavitems = all('ul.news-nav li')
      (1..5).each do |i|
        expect(newsnavitems[i - 1].find('a').text).to eq("Global News Headline #{i}")
      end
    end

    Then 'there is a news teaser ' do
      expect(page).to have_content 'Global News Headline'
      expect(page).to have_content 'To Be, Or'
    end

    Then 'the save and send button is disabled' do
      expect(page).to have_button 'Save and send', disabled: true, exact: true
    end

    Then 'I can click save and send button' do
      click_on 'Save and send', exact: true
    end

    When 'I enable the save and send button' do
      page.find(:xpath, "//label[contains(@for, 'enable-save-send')]").click
    end

    When 'I create a new announcement' do
      click_on 'Create new announcement'
    end

    When 'I fill out the announcement fields' do
      fill_in 'announcement[title]', with: 'Test Title'
      fill_in 'Publish at', with: 2.days.ago.iso8601
      fill_markdown_editor "[name='announcement[text]']", use_selector: true, with: 'Test text'
    end

    When 'I save the announcement' do
      click_on 'Save'
    end

    When 'I save and send the announcement' do
      click_on 'Save and send'
      sleep 0.1
    end

    When 'I save and send the announcement in test mode' do
      click_on 'Save and send test mail'
      sleep 0.1
    end

    When 'I draft a new targeted announcement' do
      click_on 'Draft new announcement'
    end

    When 'I fill out the targeted announcement fields' do
      within_fieldset('English') do
        fill_in 'Subject', with: 'Join our new course on MOOCs!'
        fill_markdown_editor 'Content', with: 'You already took our first course - now join the second one.'
      end

      within_fieldset('German') do
        fill_in 'Subject', with: 'Besuchen Sie unseren neuen Kurs über MOOCs!'
        fill_markdown_editor 'Content',
          with: 'Sie haben bereits unseren ersten Kurs abgeschlossen - besuchen Sie jetzt den zweiten.'
      end
    end

    When 'I save the targeted announcement' do
      click_on 'Create announcement'
    end

    Then 'I see a button to publish the new announcement via email' do
      expect(page).to have_content 'Join our new course on MOOCs!'
      expect(page).to have_content 'Publish via email'
    end

    Given 'there is a marketing treatment' do
      context.assign :treatment, create_treatment(name: 'marketing')
    end

    Given 'I consented to marketing' do
      create_and_assign_consent
    end

    When 'I publish the announcement via email' do
      click_on 'Publish via email'
    end

    When 'I select a user as the recipient' do
      context.with :user do |user|
        tom_select user['name'], from: 'Recipients', search: true
      end
    end

    When 'I select course students as the recipients' do
      context.with :course do |course|
        tom_select course['course_code'], from: 'Recipients', search: true
      end
    end

    When 'I require users to consent to marketing' do
      context.with :treatment do |treatment|
        check treatment['name']
      end
    end

    When 'I publish the announcement' do
      click_on 'Send announcement email'
    end

    When 'I publish the announcement as test email' do
      page.find('label', text: 'Send as test email?').click
      click_on 'Send announcement email'
    end

    Then 'all users should receive a targeted announcement email' do
      context.with :additional_user, :user do |additional_user, admin|
        [additional_user, admin].each do |user|
          Test.wait do # We may fetch other mails before the announcement mail
            open_email fetch_emails(to: user['email']).last
            expect(page).to have_content 'You already took our first course - now join the second one.'
          end
        end
      end
    end

    Then 'only users who have given consent to marketing receive an email' do
      context.with :user do |user|
        Test.wait do # We may fetch other mails before the test mail
          open_email fetch_emails(to: user['email']).last
          expect(page).to have_content 'You already took our first course - now join the second one.'
        end
      end
    end

    Then 'I should receive a test email with the content inherited from the announcement' do
      context.with :user do |user|
        Test.wait do # We may fetch other mails before the test mail
          open_email fetch_emails(to: user['email']).last
          expect(page).to have_content 'This is a test message, only you received this!'
          expect(page).to have_content 'You already took our first course - now join the second one.'
        end
      end
    end

    Then 'the additional user should not receive a targeted announcement mail' do
      context.with :additional_user do |user|
        expect do
          fetch_emails(to: user['email'], subject: 'Join our new course on MOOCs!', timeout: 5)
        end.to raise_error(Timeout::Error)
      end
    end

    When 'I create a new course announcement' do
      click_on 'Add new course announcement'
      sleep 0.1
    end

    Then 'I should receive an announcement email' do
      context.with :user do |user|
        open_email fetch_emails(to: user['email']).last
        expect(page).to have_content 'Test Title'
        expect(page).to have_content 'Test text'
      end
    end

    When 'I open my announcement email' do
      send :'Then I should receive an announcement email'
    end

    Then 'I should receive a test email' do
      context.with :user do |user|
        Test.wait do # We may fetch the course welcome mail before the test mail
          open_email fetch_emails(to: user['email']).last
          expect(page).to have_content 'Test Title'
          expect(page).to have_content 'This is a test message, only you received this!'
          expect(page).to have_content 'Test text'
        end
      end
    end

    Then 'the additional user should not receive a global announcement mail' do
      context.with :additional_user do |user|
        expect do
          fetch_emails(to: user['email'], subject: 'Test Title', timeout: 5)
        end.to raise_error(Timeout::Error)
      end
    end

    Then 'the additional user should not receive a course announcement mail' do
      context.with :additional_user do |user|
        expect do
          fetch_emails(to: user['email'], subject: 'Test Title: A Course :-)', timeout: 5)
        end.to raise_error(Timeout::Error)
      end
    end

    Then 'all users should receive an announcement email' do
      context.with :additional_user, :user do |additional_user, teacher|
        [additional_user, teacher].each do |user|
          Test.wait do # We may fetch the course welcome mail before the test mail
            open_email fetch_emails(to: user['email']).last
            expect(page).to have_content 'Test Title'
            expect(page).to have_content 'Test text'
          end
        end
      end
    end

    Then 'all enrolled users should receive an announcement email' do
      send :'Then all users should receive an announcement email'
    end

    Then 'unenrolled users should not receive an email' do
      context.with :third_user do |user|
        expect { fetch_emails(to: user['email'], timeout: 15) }.to raise_error Timeout::Error
      end
    end

    Then 'the announcement should be listed' do
      expect(page).to have_content 'Test Title'
    end

    When 'I click the global disable link' do
      within('#global') do
        click_on 'here'
      end
    end

    When 'I click the announcement notification disable link' do
      within('#local') do
        click_on 'here'
      end
    end

    When 'I click the forum notification disable link' do
      send :'When I click the announcement notification disable link'
    end

    When 'I use a disable link with invalid email address' do
      visit '/notification_user_settings/disable?email=foo.bar@nonsense.com&hash=nonsense&key=nonsense'
    end

    When 'I use a disable link with invalid hash' do
      context.with :user do |user|
        visit "/notification_user_settings/disable?email=#{user[:email]}&hash=nonsense&key=nonsense"
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::News }
