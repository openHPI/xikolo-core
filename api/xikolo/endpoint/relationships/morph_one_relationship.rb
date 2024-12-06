# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Relationships
      class MorphOneRelationship < Relationship
        class Factory
          def initialize(name)
            @name = name
            @types = {}
            @opts = {}
          end

          def build(&specification)
            instance_exec(&specification) if specification

            MorphOneRelationship.new @name, @types, @opts
          end

          def foreign_type(type)
            @opts[:foreign_type] = type
          end

          def foreign_key(key)
            @opts[:foreign_key] = key
          end

          def morph(name, klass)
            @types[name] = klass
          end
        end

        def initialize(name, types = {}, opts = {})
          super(name)

          @types = types
          @opts = opts
        end

        def foreign_type
          @opts[:foreign_type]
        end

        def foreign_key
          @opts[:foreign_key]
        end

        def instance_for(resource)
          if resource[foreign_key]
            morph_type = ensure_type! resource[foreign_type]
            RelationshipInstance.new self, morph_type, resource[foreign_key]
          else
            EmptyInstance.new
          end
        end

        def instance_from_linkage(linkage)
          return EmptyInstance.new if linkage.nil?

          morph_type = ensure_type! linkage['type']
          RelationshipInstance.new self, morph_type, linkage['id']
        end

        private

        def ensure_type!(type)
          @types[type] || raise("Invalid polymorphic resource type #{type}")
        end

        class RelationshipInstance
          def initialize(relationship, endpoint, id)
            @relationship = relationship
            @endpoint = endpoint
            @type = endpoint.entity_definition.type
            @id = id
          end

          def name
            @relationship.name
          end

          def serialize(_context)
            {
              name => {
                'data' => {
                  'type' => @type,
                  'id' => @id,
                },
                'links' => {
                  # TODO: This will have to be generated dynamically once we have a route map
                  'related' => "/api/v2/#{@type}/#{@id}",
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
            {
              @relationship.foreign_type => @type,
              @relationship.foreign_key => @id,
            }
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
