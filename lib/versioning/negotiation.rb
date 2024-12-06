# frozen_string_literal: true

module Versioning
  class Negotiation
    # Supported versions must not be empty and
    # must be an array of Version instances
    def initialize(supported_versions)
      if supported_versions.empty?
        raise StandardError.new('Cannot negotiate versions: versions missing')
      else
        @supported_versions = supported_versions
      end
    end

    def current_version
      @supported_versions.first
    end

    def assign_version(requested_version)
      if requested_version.blank?
        current_version
      else
        compatible_version(requested_version)
      end
    end

    private

    def compatible_version(requested_version)
      # Respond with the first available supported version
      # based on Version#compatible (major version).
      @supported_versions.reject(&:expired?).detect do |supported_version|
        supported_version.compatible? requested_version
      end
    end
  end
end
