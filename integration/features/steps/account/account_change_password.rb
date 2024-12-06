# frozen_string_literal: true

module Steps
  module Account
    module ChangePassword
      When 'I set a new password for the user' do
        context.with :additional_user do |user|
          new_password = 'secret_very_very_new'
          expect(user['password']).to_not eq new_password
          user['password'] = new_password
          fill_in 'Password', with: user['password']
        end
        click_on 'Change password'
      end

      When 'I change my password' do
        context.with :user do |user|
          click_on 'Change password'
          fill_in 'Old password', with: user['password']
          new_password = 'secret_very_very_new'
          expect(user['password']).to_not eq new_password
          user['password'] = new_password
          fill_in 'New password', with: user['password']
          fill_in 'Confirm password', with: user['password']
          click_on 'Change password'
        end
      end

      Then 'I should be notified about successful password change' do
        expect(page).to have_notice 'Your password has been successfully changed'
      end

      Then 'the additional user should be able to log in with the new password' do
        context.with :additional_user do |user|
          expect(user['password']).to eq 'secret_very_very_new'

          send :'When I log out'
          log_in user
        end
        expect_login_state
      end

      Then 'I should be able to log in with the new password' do
        context.with :user do |user|
          expect(user['password']).to eq 'secret_very_very_new'

          send :'When I log out'
          log_in user
        end
        expect_login_state
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Account::ChangePassword }
