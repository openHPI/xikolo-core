# frozen_string_literal: true

module Bridges
  module Shop
    def self.shared_secret
      Rails.application.secrets.bridge_shop
    end

    def self.configured?
      Xikolo.config.voucher['enabled'] && shared_secret.present?
    end

    class BaseController < Abstract::BridgeAPIController
      before_action do
        raise AbstractController::ActionNotFound unless Shop.configured?
      end

      before_action Xi::Controllers::RequireBearerToken.new(
        realm: 'shop-bridge-api',
        token: -> { Shop.shared_secret }
      )
    end
  end
end
