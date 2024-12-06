# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class Integer < Type
        def out(val)
          val.respond_to?(:to_i) ? val.to_i : 0
        end

        def in(val)
          raise Xikolo::Error::InvalidValue unless val.is_a?(::Integer)

          val
        end
      end
    end
  end
end
