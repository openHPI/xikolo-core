# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class DateTime < Type
        def out(val)
          val.present? ? ::DateTime.parse(val).iso8601(3) : nil
        rescue ArgumentError, TypeError
          nil
        end

        def in(val)
          return nil if val.nil?

          ::DateTime.parse(val).iso8601(3)
        rescue ArgumentError, TypeError
          raise Xikolo::Error::InvalidValue
        end
      end
    end
  end
end
