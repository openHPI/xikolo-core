# frozen_string_literal: true

module Xikolo
  module V2
    class PreferenceAPI < Grape::API::Instance
      namespace 'preferences' do
        mount Endpoint::ListPreferences

        route_param :pref_id, requirements: {pref_id: /[A-Za-z0-9_.]+/} do
          mount Endpoint::ViewPreference

          desc 'Set a preference value'
          put do
            preference_repo.set current_user.id, params[:pref_id], params[:preference][:value] if current_user.logged_in?

            status 204 # no content
          end
        end
      end
    end
  end
end
