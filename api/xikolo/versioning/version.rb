# frozen_string_literal: true

module Xikolo
  module Versioning
    class Version
      def initialize(string, **opts)
        @string = string.to_s
        @opts = opts
      end

      def compatible?(other_version)
        major == other_version.major
      end

      def major
        @major ||= parts.first
      end

      def expired?
        return false unless expires?
        # Prevent the expired state for the API if a sunset for apps is announced.
        return false if sunset_date.present?

        expiry_date.past?
      end

      def expires?
        expiry_date.present?
      end

      def expiry_date
        sunset_date.presence || @opts[:expire_on]
      end

      def to_s
        @string
      end

      private

      def parts
        @parts ||= @string.split('.')
      end

      def sunset_date
        return if Xikolo.config.api['mobile_app_sunset_date'].blank?

        Time.zone.parse(Xikolo.config.api['mobile_app_sunset_date'])
      end
    end
  end
end
