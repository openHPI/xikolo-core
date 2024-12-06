# frozen_string_literal: true

module Steps
  module Gamification
    Given 'the gamification feature is enabled' do
      set_xikolo_config('gamification', enabled: true)
    end

    Then 'I can see my user score' do
      expect(page.find('.navigation-profile-item__points').visible?).to eq true
    end

    Then 'I can see my course XP' do
      expect(page).to have_content('Your XP')
    end

    Then 'I cannot see any user score' do
      # User score in the navigation
      expect(page).not_to have_css('.navigation-profile-item__points')
      # User's XP below the course list
      expect(page).not_to have_content('Your XP')
    end
  end
end

Gurke.configure do |c|
  c.include Steps::Gamification
end
