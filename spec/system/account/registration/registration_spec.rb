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

  context 'for users blocked based on geo IP restrictions' do
    let(:anonymous_session) do
      super().merge(features: {
        'account.registration' => true,
        'geo_ip_block' => true,
      })
    end

    context 'with IPv4 address' do
      before do
        # 103.76.53.1 is an arbitrary Russian IPv4 address
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(ActionDispatch::Request)
          .to(receive(:remote_ip))
          .and_return('103.76.53.1')
        # rubocop:enable RSpec/AnyInstance
      end

      it 'does not allow access to the registration form' do
        visit '/account/new'

        expect(page).to have_content 'This website is not available in your country.'
      end
    end

    context 'with IPv6 address' do
      before do
        # 2a04:61c0::1 is an arbitrary Russian IPv6 address
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(ActionDispatch::Request)
          .to(receive(:remote_ip))
          .and_return('2a04:61c0::1')
        # rubocop:enable RSpec/AnyInstance
      end

      it 'does not allow access to the registration form' do
        visit '/account/new'

        expect(page).to have_content 'This website is not available in your country.'
      end
    end
  end
end
