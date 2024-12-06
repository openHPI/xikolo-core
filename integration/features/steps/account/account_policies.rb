# frozen_string_literal: true

module Steps
  module Account
    module Policies
      Given 'there is a policy' do
        Server[:account].api.rel(:policies)
          .post(version: 4, url: {en: 'https://google.com'})
          .value!
      end

      Given 'I have accepted current policy' do
        Server[:account].api.rel(:user)
          .patch({accepted_policy_version: 4}, {id: context.fetch(:user)[:id]})
          .value!
      end

      When 'I accept the policy' do
        click_on 'Proceed'
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Account::Policies }
