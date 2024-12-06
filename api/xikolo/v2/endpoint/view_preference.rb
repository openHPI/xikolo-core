# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ViewPreference < Xikolo::API
        desc 'Get a preference value'
        get do
          authenticate!

          pref = preference_repo.find_one current_user.id, params[:pref_id]

          present :preference, pref, with: Xikolo::Entities::Preference
        end
      end
    end
  end
end
