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

    Given 'I am on the profile edit page' do
      visit '/dashboard/profile/edit'
    end

    Given 'I am on the profile edit email page' do
      visit '/dashboard/profile/edit_email'
    end

    Given 'I am on the avatar edit page' do
      visit '/dashboard/profile/edit_avatar'
    end

    Given 'there are mandatory profile fields' do
      Rack::Remote.invoke :account, :test_mandatory_profile
    end

    When 'I delete the secondary email' do
      click_link 'Delete'

      within_dialog do
        click_on 'Yes, sure'
      end

      expect(page).to have_content('Your secondary e-mail has successfully been deleted')
    end

    When 'I add a new email address' do
      fill_in 'Add a new e-mail address', with: 'john@example.com'
      click_button 'Save'

      expect(page).to have_content('We sent you a confirmation e-mail to john@example.com.')
    end

    When 'I upload a profile image' do
      attach_file 'xikolo_account_user_avatar', asset_path('profile_image.jpg')

      click_button 'Save'
    end

    When 'I fill out the date of birth' do
      date_input = find('input[name="xikolo_account_user[born_at]"]', visible: false)
      page.execute_script("arguments[0].value = '2000-08-31'", date_input)
      click_button 'Save'

      expect(page).to have_content 'The profile has been updated'
    end

    When 'I fill out the profile form' do
      fill_in 'Name', with: 'John Doe'
      fill_in 'Display name', with: 'John Doe'

      select 'Teacher', from: 'Status'
      select 'Female', from: 'Gender'

      select 'Germany', from: 'Country', match: :first
      select 'Brandenburg', from: 'State'
      fill_in 'City', with: 'Potsdam'

      click_button 'Save'

      expect(page).to have_content 'The profile has been updated'
    end

    Then 'I see my profile' do
      expect(page).to have_content 'My profile'
    end

    Then 'I see the new profile image' do
      expect(page).to have_css("div[style*='avatar']")
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
      expect(page).to have_content '31.08.2000'
    end
  end
end

Gurke.configure {|c| c.include Steps::AccountProfile }
