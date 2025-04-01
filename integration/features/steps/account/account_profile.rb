# frozen_string_literal: true

module Steps
  module AccountProfile
    Given 'I am on the profile page' do
      visit '/'
      context.with :user do
        page.find('[aria-label="Profile menu"]').click
        click_on 'Profile'
      end
    end

    Given 'there are mandatory profile fields' do
      Rack::Remote.invoke :account, :test_mandatory_profile
    end

    When 'I upload a profile image' do
      page.execute_script("$('#user_visual_upload').removeClass('hide')")
      attach_file 'user_visual_upload', asset_path('profile_image.jpg')
    end

    When 'I fill out the date of birth' do
      find('a[data-name=born_at]').click

      within '.editable-container .month' do
        find("option[value='9']").click
      end

      within '.editable-container .day' do
        find("option[value='1']").click
      end

      within '.editable-container .year' do
        find("option[value='1998']").click
      end

      find('.editable-container button[type="submit"]').click

      # Wait for inline-edit to be successful
      expect(page).to have_selector '.editable-updated'
    end

    When 'I fill out the mandatory profile' do
      find('a[data-name=profession]').click
      find('.editable-container input[type="text"]').set 'Master of Disaster'
      find('.editable-container button[type="submit"]').click

      # Wait for inline-edit to be successful
      expect(page).to have_selector '.editable-updated'
    end

    Then 'I see my profile' do
      expect(page).to have_content 'My profile'
    end

    Then 'I see the new profile image' do
      expect(page).to have_xpath "//input[contains(@src, 'avatar')]"
    end

    Then "I see the additional user's primary email address" do
      send 'Given I am logged in'
      send 'Given I am on his user detail page'

      context.with :additional_user do |user|
        email = user.fetch('email')
        expect(email).to be_present

        expect(page).to have_link(email, href: "mailto:#{email}", count: 1)
      end
    end

    Then "I do not see the additional user's primary email address" do
      send 'Given I am logged in'
      send 'Given I am on his user detail page'

      context.with :additional_user do |user|
        email = user.fetch('email')
        expect(email).to be_present

        expect(page).to have_no_link(email)
      end
    end

    Then 'I see the new birthday date' do
      expect(page).to have_text 'October 1, 1998'
    end
  end
end

Gurke.configure {|c| c.include Steps::AccountProfile }
