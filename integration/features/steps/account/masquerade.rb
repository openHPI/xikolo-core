# frozen_string_literal: true

module Steps
  module Account
    module Masquerade
      When 'I open the users list' do
        visit '/'
        click_on 'Administration'
        click_on 'Users'
      end

      When 'I search for the other user' do
        context.with :additional_user do |user|
          fill_in 'Filter by name or email:', with: user[:email]
          find('#user_filter_query').native.send_keys(:return)
        end
      end

      When 'I masquerade as this user' do
        click_on 'Details'
        click_on 'Masquerade as user'
        # When masquerading, expect to be redirected to the user's dashboard.
        expect(page).to have_content 'My upcoming courses'
      end

      When 'I demasquerade' do
        click_on 'DEMASQ'
      end

      Then 'I should be masquerade as this user' do
        expect(page).to have_link 'DEMASQ'
        context.with :additional_user do |user|
          expect(page).to have_selector("[title='#{user[:full_name]}']")
        end
      end

      Then 'I am again myself' do
        expect(page).to_not have_link 'DEMASQ'
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Account::Masquerade }
