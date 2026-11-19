# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Admin edits video provider', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }
  let(:provider) { create(:video_provider, :vimeo) }

  before do
    provider
    sign_in(user: admin)
    click_on 'Administration'
    click_on 'Videos'
    click_on 'Video Providers'
  end

  it 'edits a provider' do
    find('[aria-label="More actions"]').click
    within '[data-behaviour="menu-dropdown"]' do
      click_on 'Edit'
    end

    fill_in 'Name', with: 'new name'
    click_on 'Update Provider'

    expect(page).to have_text 'new name'
  end
end
