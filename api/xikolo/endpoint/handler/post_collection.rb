# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Handler
      ##
      # Processes POST requests to a collection resource.

      class PostCollection
        def initialize(endpoint)
          @endpoint = endpoint
        end

        def run(block, context, grape)
          definition = @endpoint
            .entity_definition
            .for_version(context.env['XIKOLO_API_VERSION'])
          entity_or_entities = definition.from_json_api context.env['rack.request.form_hash']

          if entity_or_entities.is_a? Array
            collection = entity_or_entities.map do |entity|
              context.sub_request(block, parsed_body: entity).value!
            end

            context.document.data = definition.from_collection collection
          else
            resource = context.sub_request(block, parsed_body: entity_or_entities).value!

            context.document.data = definition.from_member resource
          end

          grape.content_type 'application/vnd.api+json'
          ::Oj.dump context.document.serialize(context), mode: :strict
        rescue Xikolo::Endpoint::NonWritableAttribute => e
          raise Xikolo::Error::BadRequest.new(e.message)
        end
      end
    end
  end
end
