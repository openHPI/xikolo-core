# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Filter
      ##
      # Represents a required query filter.
      #
      # If the filter is not found in a hash of query params, it will raise an exception.

      class Required
        def initialize(name)
          @name = name
          @desc = ''
          @alias = nil
        end

        def required?
          true
        end

        def description(text = nil)
          return @desc unless text

          @desc = text
        end

        def alias_for(key)
          @alias = key
        end

        def extract(filters)
          filter = filters[@name]

          raise InvalidFilter.new("Required filter #{@name} not found") if filter.nil?

          {@alias || @name => filter}
        end
      end
    end
  end
end
