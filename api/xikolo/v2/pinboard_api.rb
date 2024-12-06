# frozen_string_literal: true

module Xikolo
  module V2
    class PinboardAPI < Grape::API::Instance
      namespace 'threads' do
        mount Endpoint::ListThreads
      end

      namespace 'pinboard_tags' do
        mount Endpoint::ListPinboardTags
      end

      namespace 'pinboard_sections' do
        mount Endpoint::ListPinboardSections

        route_param :id, type: String, desc: 'The section UUID' do
          mount Endpoint::ViewPinboardSection
        end
      end

      namespace 'pinboard_subscriptions' do
        mount Endpoint::ListPinboardSubscriptions
        route_param :subscription_id do
          mount Endpoint::EditSubscription
        end
      end
    end
  end
end
