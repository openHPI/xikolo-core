# frozen_string_literal: true

module Bridges
  module Lanalytics
    def self.shared_secret
      Rails.application.secrets.bridge_lanalytics
    end

    def self.configured?
      shared_secret.present?
    end

    class BaseController < Abstract::BridgeAPIController
      before_action do
        raise AbstractController::ActionNotFound unless Lanalytics.configured?
      end

      before_action Xi::Controllers::RequireBearerToken.new(
        realm: 'lanalytics-bridge-api',
        token: -> { Lanalytics.shared_secret }
      )
    end
  end
end
