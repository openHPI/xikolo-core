# frozen_string_literal: true

require 'account_service/provider/base'
require 'account_service/provider/saml'
require 'account_service/provider/saml_test_id'
require 'account_service/provider/hpi'
require 'account_service/provider/hpi_saml'
require 'account_service/provider/mein_bildungsraum'

module AccountService
  module Provider
    class << self
      def find(name)
        "AccountService::Provider::#{name.camelize}".constantize
      rescue NameError
        nil
      end

      def call(authorization, auto_create: false)
        provider = find(authorization.provider)
        raise ArgumentError.new 'Authorization provider not found' unless provider

        provider.new(authorization).call(auto_create:)
      end

      def update(authorization)
        if authorization.user.blank?
          raise ArgumentError.new 'Authorization must have a user'
        end

        return unless (provider = find(authorization.provider))

        provider.new(authorization).update(authorization.user)
      end
    end

    class Error < StandardError
      def initialize(msg)
        [msg].flatten.each {|s| errors << s }
        super
      end

      def errors
        @errors ||= []
      end
    end
  end
end
