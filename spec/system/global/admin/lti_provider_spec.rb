# frozen_string_literal: true

require 'spec_helper'

describe 'Global: Create a global LTI Provider', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    sign_in(user: admin)
  end

  it 'cancels modal to set privacy back to anonymized' do
    visit '/admin/lti_providers'

    click_on 'Create new LTI Provider'

    fill_in 'Name', with: 'LTI provider 1'
    fill_in 'Launch URL', with: 'https://www.example.com/launch'
    fill_in 'OAuth consumer key', with: 'oauth_consumer_key'
    fill_in 'OAuth secret', with: 'oauth_secret'

    choose 'unprotected'

    expect(page).to have_text("If the provider is 'unprotected', personal data might be passed to third parties")

    click_on "Reset to 'anonymized'"

    expect(page).to have_checked_field 'anonymized'

    click_on 'Save'

    expect(page).to have_current_path '/admin/lti_providers'
    expect(page).to have_text 'LTI provider 1'
    expect(page).to have_text 'https://www.example.com/launch'
  end

  it 'confirms modal to set privacy value unprotected' do
    visit '/admin/lti_providers'

    click_on 'Create new LTI Provider'

    fill_in 'Name', with: 'LTI provider 1'
    fill_in 'Launch URL', with: 'https://www.example.com/launch'
    fill_in 'OAuth consumer key', with: 'oauth_consumer_key'
    fill_in 'OAuth secret', with: 'oauth_secret'

    choose 'unprotected'

    expect(page).to have_text("If the provider is 'unprotected', personal data might be passed to third parties")

    click_on 'Confirm'

    expect(page).to have_checked_field 'unprotected'

    click_on 'Save'

    expect(page).to have_current_path '/admin/lti_providers'
    expect(page).to have_text 'LTI provider 1'
    expect(page).to have_text 'https://www.example.com/launch'
  end
end
