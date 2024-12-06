# frozen_string_literal: true

module Steps
  module Account
    module Places
      Given "I am on the additional user's detail page" do
        context.with :additional_user do |user|
          visit "/users/#{user['id']}"
        end
      end

      Given 'I am on the profile settings page' do
        visit '/preferences'
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Account::Places }
