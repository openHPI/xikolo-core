# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Handler
      ##
      # Processes DELETE requests to a singular resource.

      class DeleteMember
        def initialize(entity)
          @entity = entity
        end

        def run(block, context, grape)
          context.exec(block).value!

          grape.body false
        rescue Xikolo::Error::NotFound => e
          grape.error! e.message, 404
        end
      end
    end
  end
end
