# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Relationships
      class Relationship
        def initialize(name)
          @name = name

          @includable = false
        end

        attr_reader :name
        attr_writer :includable

        # Determine whether the relationship can be sideloaded
        def includable?
          @includable
        end

        # Determine whether the relationship should be included in the response document by default
        def include?
          false
        end

        def route?
          false
        end
      end
    end
  end
end
