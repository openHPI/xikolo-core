# frozen_string_literal: true

require 'spec_helper'

describe 'Global: Gamification', type: :system do
  let(:user) { create(:'account_service/user') }

  it 'sees user score' do
    sign_in(user: user)
    visit '/'
    expect(page).to have_current_path(%r{/})
    expect(page).to have_css('.navigation-profile-item__points')
    visit '/dashboard/achievements'
    expect(page).to have_text('Your XP')
  end

  it 'cannot see a user score when logged out' do
    visit '/'
    expect(page).to have_current_path(%r{/})
    expect(page).to have_no_css('.navigation-profile-item__points')
    expect(page).to have_no_text('Your XP')
  end
end
