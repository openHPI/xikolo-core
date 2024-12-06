# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Relationships
      class HasManyRelationship < Relationship
        class Factory
          def initialize(name, klass)
            @name = name
            @klass = klass
            @opts = {
              filters: {},
            }
          end

          def build(&specification)
            instance_exec(&specification) if specification

            HasManyRelationship.new @name, @klass, @opts
          end

          # Define which of the resource's attributes should be used for filtering
          #
          # The first parameter must map to an existing filter on the related endpoint.
          # The optional second parameter provides the name of this resource's attribute
          # which identifies the resource (for use with the filter).
          def foreign_key(filter_name, identifier_key = 'id')
            @opts[:foreign_key_filter] = filter_name
            @opts[:foreign_key_attr] = identifier_key
          end
          alias filter_by foreign_key

          # Provide additional filtering blocks
          #
          # Each block will be used to dynamically generate the value of the related
          # endpoint's filter identified by the first attribute.
          #
          # The block will be executed in the request's scope, so that it can access
          # data e.g. from the request or current user.
          def filter(name, &filter_block)
            @opts[:filters][name] = filter_block
          end

          # Define how to extract the related resources from the input data
          #
          # The block will receive the resource hash and should extract and return an array that can be
          # used as input to serialize the related resources.
          def embedded(&block)
            @opts[:loader] = block
          end
        end

        def initialize(name, klass, opts = {})
          super(name)

          if opts[:loader]
            @loader = opts[:loader]
          elsif opts[:foreign_key_filter]
            @foreign_key = {
              filter: opts[:foreign_key_filter],
              attr: opts[:foreign_key_attr] || 'id',
            }
          else
            raise ArgumentError.new('You need to provide either the :loader or the :foreign_key_filter (and optionally :foreign_key_attr) option')
          end

          @klass = klass
          @filters = opts[:filters] || {}
        end

        def filters(resource, context)
          {
            @foreign_key[:filter] => resource[@foreign_key[:attr]],
          }.merge(
            @filters.transform_values {|block|
              context.instance_exec(&block)
            }.compact
          )
        end

        def instance_for(resource)
          if @loader
            IncludedInstance.new self, @klass, @loader.call(resource)
          else
            RelationshipInstance.new self, @klass, resource
          end
        end

        def instance_from_linkage(_linkage)
          EmptyInstance.new
        end

        class RelationshipInstance
          def initialize(relationship, endpoint, resource)
            @relationship = relationship
            @endpoint = endpoint
            @resource = resource

            @loaded = false
          end

          def name
            @relationship.name
          end

          def serialize(context)
            filters = @relationship.filters(@resource, context)

            {
              name => {
                'links' => {
                  'related' => "/api/v2/#{@endpoint.entity_definition.type}?#{filters.to_query('filter')}",
                },
              }.tap {|hash|
                hash['data'] = @related.value!.map(&:identifier) if @loaded
              },
            }
          end

          def related(context)
            @loaded = true

            # Send the implicit filter along to the other endpoint so that the subresource is properly filtered
            filters = @endpoint.filter_definition.determine_from(
              @relationship.filters(@resource, context)
            )

            @related = context.cached_sub_request(
              @endpoint.collection_routes[:get],
              filters:
            ).then do |collection|
              @endpoint
                .entity_definition
                .for_version(context.env['XIKOLO_API_VERSION'])
                .from_collection(collection)
            end
          end

          def to_resource
            {}
          end
        end

        class IncludedInstance
          def initialize(relationship, endpoint, embedded)
            @relationship = relationship
            @entity = endpoint.entity_definition
            @embedded = embedded

            @loaded = !!embedded
          end

          def name
            @relationship.name
          end

          def serialize(_context)
            {
              name => {
                'data' => @entity
                  .from_collection(@embedded)
                  .map(&:identifier),
              },
            }
          end

          def related(context)
            Restify::Promise.fulfilled @entity
              .for_version(context.env['XIKOLO_API_VERSION'])
              .from_collection(@embedded)
          end

          def to_resource
            {}
          end
        end

        class EmptyInstance
          def serialize(_context)
            {}
          end

          def related(_)
            Restify::Promise.fulfilled []
          end

          def to_resource
            {}
          end
        end
      end
    end
  end
end
