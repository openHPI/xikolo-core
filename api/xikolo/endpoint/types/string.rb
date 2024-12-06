# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class String < Type
        def out(val)
          case val
            when ::Numeric, ::String
              val.to_s
          end
        end

        def in(val)
          return val if val.nil? || val.is_a?(::String)

          raise Xikolo::Error::InvalidValue
        end
      end
    end
  end
end
