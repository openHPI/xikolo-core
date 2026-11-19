# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Create video provider', type: :system do
  before do
    sign_in(user: create(:'account_service/user', :admin))
  end

  it 'creates a new Vimeo provider' do
    visit '/admin/video_providers'

    click_on 'Create new video provider'
    click_on 'Vimeo'
    fill_in 'Name', with: 'test_provider'
    fill_in 'Token', with: 'test_token'
    click_on 'Create Provider'

    expect(page).to have_text 'test_provider'
    expect(page).to have_no_text 'test_token'
  end
end
