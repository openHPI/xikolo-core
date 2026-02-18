# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Register new Account', type: :system do
  before do
    Stub.request(:account, :get, '/treatments')
      .to_return(Stub.json([]))
  end

  context 'with native registration enabled' do
    let(:anonymous_session) do
      super().merge(features: {'account.registration' => true})
    end

    it 'prefills the form from query parameters' do
      visit '/account/new?full_name=Bello+Flachner&email=bello.flachner%40sub.com'

      expect(page).to have_field 'Name', with: 'Bello Flachner'
      expect(page).to have_field 'E-mail address', with: 'bello.flachner@sub.com'
    end

    it 'shows an error message when the password confirmation is wrong' do
      visit '/account/new'

      fill_in 'Name', with: 'Jane Doe'
      fill_in 'E-mail address', with: 'doe@plattner.de'
      select 'Teacher', from: 'Status'
      fill_in 'Date of birth', with: '01.01.2000'
      fill_in 'Password', with: 'secret'
      fill_in 'Repeat password', with: 'wrong_secret'

      click_on 'Register for openHPI'

      expect(page).to have_content "doesn't match Password"
    end
  end
end
