# frozen_string_literal: true

module Xikolo
  module V2::User
    class Profile < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'user-profile'

        attribute('full_name') {
          description 'The user\'s full name'
          type :string
        }

        attribute('display_name') {
          description 'The user\'s display name'
          type :string
        }

        attribute('email') {
          description 'The user\'s primary email address'
          type :string
        }
      end

      member do
        get 'Load information about a user' do
          # Only the user themselves should be allowed to access their own profile.
          # (The "profile ID" that is passed in here is the ID of the user whose data we want to see.)
          authenticate_as! id

          Xikolo.api(:account).value!.rel(:user).get(id:).value!
        end
      end
    end
  end
end
