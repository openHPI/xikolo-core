# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListPreferences < Xikolo::API
        desc 'Returns all preferences for the current user'
        get do
          preferences = []
          preferences = preference_repo.find_all current_user.id if current_user.logged_in?

          present :preferences, preferences, with: Xikolo::Entities::Preference
        end
      end
    end
  end
end
