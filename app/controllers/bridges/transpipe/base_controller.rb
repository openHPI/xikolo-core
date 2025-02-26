# frozen_string_literal: true

module Bridges
  module Transpipe
    def self.shared_secret
      Rails.application.secrets.bridge_transpipe
    end

    def self.realm
      Xikolo.config.transpipe['realm']
    end

    class BaseController < Abstract::BridgeAPIController
      protected

      def course_api
        @course_api ||= Xikolo.api(:course).value!
      end

      private

      def problem_details(title, status:, **)
        render(
          content_type: 'application/problem+json',
          json: {
            title:,
            status: Rack::Utils.status_code(status),
          },
          status:,
          **
        )
      end
    end
  end
end
