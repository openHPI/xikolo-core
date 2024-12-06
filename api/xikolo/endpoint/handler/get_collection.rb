# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Handler
      ##
      # Processes GET requests to a collection resource.

      class GetCollection
        def initialize(endpoint)
          @endpoint = endpoint
        end

        def run(block, context, grape)
          context.env['xikolo.api.request.filters'] = filters(context)

          sideloader(context).with_includes do
            # Fetch the collection
            resource = context.exec(block).value!

            # Add the navigation links and meta information to the JSON-API document
            pagination.amend_document(resource, context) if pagination_enabled?

            context.document.data = @endpoint
              .entity_definition
              .for_version(context.env['XIKOLO_API_VERSION'])
              .from_collection(resource)
          end

          grape.content_type 'application/vnd.api+json'
          ::Oj.dump context.document.serialize(context), mode: :strict
        rescue Xikolo::Endpoint::Filter::InvalidFilter => e
          raise Xikolo::Error::BadRequest.new(e.message)
        end

        private

        def sideloader(context)
          Xikolo::Endpoint::IncludeRelatedResources.new(
            @endpoint.entity_definition,
            context.document,
            context.query['include']
          )
        end

        def pagination_enabled?
          @endpoint.pagination?
        end

        def pagination
          @endpoint.pagination
        end

        def filters(context)
          @endpoint.filter_definition.determine_from(context.query['filter'].to_h).tap {|base_filters|
            base_filters.merge! pagination.filters(context) if pagination_enabled?
          }
        end
      end
    end
  end
end
