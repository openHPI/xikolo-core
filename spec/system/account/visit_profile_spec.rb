# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Visit profile', type: :system do
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user: user)
    visit '/dashboard/profile'
  end

  it 'sees my profile' do
    expect(page).to have_text('My profile')
  end
end
