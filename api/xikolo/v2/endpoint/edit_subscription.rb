# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class EditSubscription < Xikolo::API
        desc 'Unsubscribes a Subscription', object_fields: Xikolo::Entities::PinboardSubscription.documentation
        delete do
          Xikolo.api(:pinboard).value!.rel(:subscription).delete(
            id: params[:subscription_id]
          ).value!
          status :no_content
        rescue StandardError
          status 404
        end
      end
    end
  end
end
