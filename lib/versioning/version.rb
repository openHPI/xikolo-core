# frozen_string_literal: true

module Versioning
  class Version
    def initialize(version, **opts)
      @version = version
      @expiry_date = opts[:expire_on]
    end

    attr_reader :expiry_date

    def compatible?(other_version)
      if other_version.is_a? String
        major == other_version.split('.').first
      else
        major == other_version.major
      end
    end

    def expired?
      return false unless expires?

      @expiry_date.past?
    end

    def expires?
      @expiry_date.present?
    end

    def to_s
      @version
    end

    private

    def parts
      @parts ||= @version.split('.')
    end

    def major
      @major ||= parts.first
    end
  end
end
