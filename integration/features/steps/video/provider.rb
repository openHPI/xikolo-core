# frozen_string_literal: true

module Steps
  module Provider
    When 'I fill in the video provider form for Vimeo' do
      click_on 'Create new video provider'
      click_on 'Vimeo'
      fill_in 'Name', with: 'test_provider'
      fill_in 'Token', with: 'test_token'
      click_on 'Create Provider'
    end

    Then 'I should see the default vimeo provider' do
      expect(page).to have_content 'default_vimeo_provider'
    end

    Then 'I should see the new video provider' do
      expect(page).to have_content 'test_provider'
    end

    Then 'I should not see the token' do
      expect(page).to_not have_content 'test_token'
    end

    When 'I edit the provider' do
      find('[aria-label="More actions"]').click
      within '[data-behaviour="menu-dropdown"]' do
        click_on 'Edit'
      end
    end

    When 'I change the name' do
      fill_in 'Name', with: 'new name'
      click_on 'Update Provider'
    end

    Then 'the name should be updated' do
      expect(page).to have_content 'new name'
    end
  end
end

Gurke.configure {|c| c.include Steps::Provider }
