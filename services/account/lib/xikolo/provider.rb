# frozen_string_literal: true

module Xikolo
  module Provider
    class << self
      def find(name)
        "Xikolo::Provider::#{name.camelize}".constantize
      rescue NameError
        nil
      end

      def call(authorization, auto_create: false)
        provider = find(authorization.provider)
        raise ArgumentError.new 'Authorization provider not found' unless provider

        trace(authorization, provider, 'call') do
          provider.new(authorization).call(auto_create:)
        end
      end

      def update(authorization)
        if authorization.user.blank?
          raise ArgumentError.new 'Authorization must have a user'
        end

        return unless (provider = find(authorization.provider))

        trace(authorization, provider, 'update') do
          provider.new(authorization).update(authorization.user)
        end
      end

      private

      def trace(authorization, provider, action, &)
        meta = {
          authorization: authorization.id,
          provider: authorization.provider,
          provider_class: provider.to_s,
        }

        ::Mnemosyne.trace("lib.provider.#{action}", meta:, &)
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
