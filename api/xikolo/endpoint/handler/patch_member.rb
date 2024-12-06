# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Handler
      ##
      # Processes PATCH requests to a singular resource.

      class PatchMember
        def initialize(entity)
          @entity = entity
        end

        def run(block, context, grape)
          definition = @entity.for_version(context.env['XIKOLO_API_VERSION'])
          entity = definition.from_json_api context.env['rack.request.form_hash']

          raise Xikolo::Error::Conflict.new('Wrong ID') if entity.id != context.id

          # Pass the entity to the context
          context.env['xikolo.api.request.body.parsed'] = entity

          context.document.data = definition.from_member context.exec(block).value!

          grape.content_type 'application/vnd.api+json'
          ::Oj.dump context.document.serialize(context), mode: :strict
        rescue Xikolo::Endpoint::NonWritableAttribute => e
          raise Xikolo::Error::BadRequest.new(e.message)
        end
      end
    end
  end
end
