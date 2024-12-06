# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Handler
      ##
      # Processes GET requests to a singular resource.

      class GetMember
        def initialize(entity)
          @entity = entity
        end

        def run(block, context, grape)
          sideloader(context).with_includes do
            context.document.data = @entity
              .for_version(context.env['XIKOLO_API_VERSION'])
              .from_member(context.exec(block).value!)
          end

          grape.content_type 'application/vnd.api+json'
          ::Oj.dump context.document.serialize(context), mode: :strict
        end

        private

        def sideloader(context)
          Xikolo::Endpoint::IncludeRelatedResources.new(
            @entity,
            context.document,
            context.query['include']
          )
        end
      end
    end
  end
end
