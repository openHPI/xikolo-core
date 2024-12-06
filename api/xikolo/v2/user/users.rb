# frozen_string_literal: true

module Xikolo
  module V2::User
    class Users < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'users'

        attribute('name') {
          description 'The user\'s display name'
          type :string
        }

        attribute('avatar_url') {
          type :string
          reading {|user|
            Xikolo::V2::URL.avatar_url user['id'], width: 1000, height: 1000
          }
        }

        includable has_one('profile', Xikolo::V2::User::Profile) {
          foreign_key 'id'
        }

        link('self') {|user| "/api/v2/users/#{user['id']}" }
      end

      member do
        get 'Load information about a user (use "me" as ID if the current user\'s ID is not available)' do
          authenticate!

          Xikolo.api(:account).value!.rel(:user).get(
            id: id == 'me' ? current_user.id : id
          ).value!
        end
      end
    end
  end
end
