# frozen_string_literal: true

module Xikolo
  module Endpoint
    class FilterRegistration
      def initialize
        @filters = {}
      end

      attr_reader :filters

      def from(&)
        instance_exec(&)
      end

      def required(key, &)
        filter(key, Filter::Required.new(key), &)
      end

      def optional(key, &)
        filter(key, Filter::Optional.new(key), &)
      end

      # Extract and transform valid filter values from the given hash of filters
      #
      # This applies default values and/or aliasing, depending on the type of filter.
      # In addition, an exception will be raised if e.g. a required filter is missing.
      def determine_from(filter_hash)
        @filters.map {|_, filter|
          filter.extract filter_hash
        }.reduce({}, :merge)
      end

      private

      def filter(key, instance, &block)
        @filters[key] = instance

        instance.instance_exec(&block) if block
      end
    end
  end
end
