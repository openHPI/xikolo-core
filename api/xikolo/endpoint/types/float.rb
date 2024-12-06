# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class Float < Type
        def out(val)
          val.respond_to?(:to_f) ? val.to_f : 0.0
        end

        def in(val)
          Float(val)
        rescue ArgumentError, TypeError
          raise Xikolo::Error::InvalidValue
        end
      end
    end
  end
end
