# frozen_string_literal: true

module Xikolo
  module Endpoint
    ##
    # Determines which relationships of the current resource should be sideloaded
    # and instructs the resources to do so.

    class IncludeRelatedResources
      def initialize(entity, document, include_string)
        @entity = entity
        @document = document
        @include_string = include_string.to_s

        @includes = []
      end

      # Validate and load related resources as defined in the request
      #
      # This method will verify and queue the requested sideloadable relationships, before yielding
      # control back to the passed block. After the block has finished, each of the subresources
      # will be loaded for inclusion in the final response document.
      def with_includes
        determine_includes!

        yield

        @document.include!(*@includes)
      end

      private

      def determine_includes!
        # An endpoint MAY return resources related to the primary data by default.
        if requested_includes.empty?
          @includes = @entity.default_includes
          return
        end

        # An endpoint MAY also support an include request parameter to allow the client to customize which
        # related resources should be returned...

        # If an endpoint does not support the include parameter, it MUST respond with 400 Bad Request to
        # any requests that include it.
        raise Xikolo::Error::BadRequest.new('include parameter not supported for this endpoint') if includables.empty?

        # If a server is unable to identify a relationship path or does not support inclusion of resources
        # from a path, it MUST respond with 400 Bad Request.
        requested_includes.each {|rel|
          unless includables.include? rel
            raise Xikolo::Error::BadRequest.new("Relationship #{rel} does not support sideloading. Valid relationships: [#{includables.join ','}]")
          end
        }

        # If an endpoint supports the include parameter and a client supplies it, the server MUST NOT
        # include unrequested resource objects in the included section of the compound document.
        @includes = requested_includes
      end

      def includables
        @includables ||= @entity.includable_relationships
      end

      def requested_includes
        @requested_includes ||= @include_string.split ','
      end
    end
  end
end
