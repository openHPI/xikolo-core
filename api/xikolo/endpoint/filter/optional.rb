# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Filter
      ##
      # Represents an optional query filter.

      class Optional
        def initialize(name)
          @name = name
          @desc = ''
          @alias = nil
        end

        def required?
          false
        end

        def description(text = nil)
          return @desc unless text

          @desc = text
        end

        def alias_for(key)
          @alias = key
        end

        def extract(filters)
          if filters.key? @name
            {@alias || @name => filters[@name]}
          else
            {}
          end
        end
      end
    end
  end
end
