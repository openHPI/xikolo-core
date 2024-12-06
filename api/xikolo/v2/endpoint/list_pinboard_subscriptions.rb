# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListPinboardSubscriptions < Xikolo::API
        desc 'List all the subscriptions for a user'
        get do
          authenticate!
          header 'Cache-Control', 'no-cache'

          apiparams = {
            with_question: true,
            user_id: current_user.id,
            page: params[:page] || 1,
            per_page: params[:per_page] || 50,
          }
          pinboard_subscriptions = Xikolo.api(:pinboard).value!
            .rel(:subscriptions).get(apiparams).value!

          meta = {
            page: apiparams[:page],
            perPage: apiparams[:per_page],
            totalPages: pinboard_subscriptions.response.headers['X_TOTAL_PAGES'],
          }
          present meta, root: :meta

          present :pinboard_subscriptions, pinboard_subscriptions,
            with: Xikolo::Entities::PinboardSubscription
        end
      end
    end
  end
end
