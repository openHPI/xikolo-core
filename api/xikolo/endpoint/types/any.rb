# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class Any < Type
        def out(val)
          val
        end

        def in(val)
          val
        end
      end
    end
  end
end
