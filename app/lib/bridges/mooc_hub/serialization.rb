# frozen_string_literal: true

module Bridges
  module MoocHub
    ##
    # Handles version selection and delegates to a specific serializers.
    #
    class Serialization
      def initialize(version_mapping)
        @version_mapping = version_mapping
      end

      def supported_versions
        @version_mapping.keys
      end

      def serialize(resources, version:, **)
        serializer = @version_mapping.fetch(version)
        serializer.new(**).serialize(resources)
      end
    end
  end
end
