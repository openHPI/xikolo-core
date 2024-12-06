# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Relationships
      class HasOneRelationship < Relationship
        class Factory
          def initialize(name, klass)
            @name = name
            @klass = klass
            @opts = {}
          end

          def build(&specification)
            instance_exec(&specification) if specification

            HasOneRelationship.new @name, @klass, @opts
          end

          def foreign_key(key)
            @opts[:foreign_key] = key
          end

          # Define how to extract the related resource from the input data
          #
          # The block will receive the resource hash and should extract and return a hash that can be
          # used as input to serialize the related resource.
          def embedded(&block)
            @opts[:loader] = block
          end
        end

        def initialize(name, klass, opts = {})
          super(name)

          @klass = klass
          @opts = opts
        end

        def foreign_key
          @opts[:foreign_key]
        end

        def foreign_type
          @klass.entity_definition.type
        end

        def instance_for(resource)
          if @opts[:loader]
            IncludedInstance.new self, @klass.entity_definition, @opts[:loader].call(resource)
          elsif resource[foreign_key]
            LinkInstance.new self, @klass, resource[foreign_key]
          else
            EmptyInstance.new
          end
        end

        def instance_from_linkage(linkage)
          return EmptyInstance.new if linkage.nil?

          LinkInstance.new self, @klass, linkage['id']
        end

        class LinkInstance
          def initialize(relationship, endpoint, id)
            @relationship = relationship
            @endpoint = endpoint
            @id = id
          end

          def name
            @relationship.name
          end

          def serialize(_context)
            {
              name => {
                'data' => {
                  'type' => @relationship.foreign_type,
                  'id' => @id,
                },
                'links' => {
                  # TODO: This will have to be generated dynamically once we have a route map
                  'related' => "/api/v2/#{@relationship.foreign_type}/#{@id}",
                },
              },
            }
          end

          def related(context)
            context.cached_sub_request(
              @endpoint.member_routes[:get],
              id: @id
            ).then do |member|
              @endpoint
                .entity_definition
                .for_version(context.env['XIKOLO_API_VERSION'])
                .from_member(member)
            end
          end

          def to_resource
            {@relationship.foreign_key => @id}
          end
        end

        class IncludedInstance
          def initialize(relationship, entity, embedded)
            @relationship = relationship
            @entity = entity
            @embedded = embedded
          end

          def name
            @relationship.name
          end

          def serialize(_context)
            {}.tap {|hash|
              if @embedded
                hash[name] = {
                  'data' => @entity.from_member(@embedded).identifier,
                }
              end
            }
          end

          def related(context)
            return Restify::Promise.fulfilled([]) unless @embedded

            Restify::Promise.fulfilled @entity
              .for_version(context.env['XIKOLO_API_VERSION'])
              .from_member(@embedded)
          end

          def to_resource
            return {} unless @embedded

            {@relationship.foreign_key => @embedded.id}
          end
        end

        class EmptyInstance
          def serialize(_context)
            {}
          end

          def related(_)
            Restify::Promise.fulfilled([])
          end

          def to_resource
            {}
          end
        end
      end
    end
  end
end
