# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class Boolean < Type
        def out(val)
          !!val
        end

        def in(val)
          if [true, false].include? val
            val
          else
            raise Xikolo::Error::InvalidValue
          end
        end
      end
    end
  end
end
