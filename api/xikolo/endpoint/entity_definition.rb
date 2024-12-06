# frozen_string_literal: true

module Xikolo
  module Endpoint
    class EntityDefinition
      class Factory
        def initialize
          @type = nil
          @attributes = []
          @relationships = {}
          @links = {}
          @opts = {}
        end

        def build(&specification)
          instance_exec(&specification) if specification

          EntityDefinition.new(@type, @attributes, @relationships, @links, **@opts)
        end

        def type(name)
          @type = name
        end

        def id(&builder)
          @opts[:id_builder] = builder
        end

        def attribute(name, &)
          Endpoint::EntityAttribute::Factory.new(name).build(&).tap {|attribute|
            @attributes << attribute
          }
        end

        def writable(attribute)
          attribute.tap {|attr|
            attr.writable = true
          }
        end

        def member_only(attribute)
          attribute.tap {|attr|
            attr.member_only = true
          }
        end

        def has_many(name, klass, &) # rubocop:disable Naming/PredicateName
          relationship Endpoint::Relationships::HasManyRelationship::Factory.new(name, klass).build(&)
        end

        def has_one(name, klass, &) # rubocop:disable Naming/PredicateName
          relationship Endpoint::Relationships::HasOneRelationship::Factory.new(name, klass).build(&)
        end

        def morph_one(name, &)
          relationship Endpoint::Relationships::MorphOneRelationship::Factory.new(name).build(&)
        end

        # Mark a relationship as includable
        #
        # The passed relationship object will be marked as includable, which means it will be
        # possible to optionally sideload this relationship using the `include` query parameter.
        def includable(relationship)
          relationship.tap {|rel|
            rel.includable = true
          }
        end

        def link(name, &url_generator)
          @links[name] = Endpoint::EntityLink.new(name, url_generator)
        end

        private

        def relationship(relationship)
          @relationships[relationship.name] = relationship
        end
      end

      def initialize(type = nil, attributes = [], relationships = {}, links = {}, **opts) # rubocop:disable Metrics/ParameterLists
        @type = type
        @attributes = attributes
        @relationships = relationships
        @links = links

        @id_builder = opts[:id_builder] || proc {|resource| resource['id'] }

        @version_hash = Hash.new do |cache, version|
          cache[version] = self.class.new(
            @type,
            @attributes.select {|attr|
              attr.version_constraint.satisfy?(version)
            },
            @relationships,
            @links,
            id_builder: @id_builder
          )
        end
      end

      attr_reader :type, :attributes, :links

      def for_version(version)
        @version_hash[version]
      end

      def relationships
        @relationships.values
      end

      # Returns an array of names of the relationships that allow sideloading
      def includable_relationships
        @relationships.values.select(&:includable?).map(&:name)
      end

      # Returns an array of names of the relationships that should be sideloaded by default
      def default_includes
        @relationships.values.select(&:include?).map(&:name)
      end

      def rel?(name)
        @relationships.key? name
      end

      def rel(name)
        @relationships.fetch name
      end

      def from_collection(collection)
        filtered_attributes = @attributes.reject(&:member_only)

        collection.map {|member|
          entity_to_data member, filtered_attributes
        }
      end

      def from_member(member)
        entity_to_data member, @attributes
      end

      def from_json_api(json)
        fail! 'Can not parse body data' unless json.is_a? Hash

        data = json['data']

        if data.is_a? Array
          data.map {|row| data_to_entity row }
        else
          data_to_entity data
        end
      end

      private

      def entity_to_data(entity, attributes)
        Xikolo::JSONAPI::Entity.new(
          self,
          @id_builder.call(entity),
          attributes.map {|attr| attr.read(entity) }.reduce({}, :merge),
          @relationships.transform_values {|rel| rel.instance_for(entity) },
          @links.transform_values {|link| link.prepare(entity) }
        )
      end

      def data_to_entity(data)
        conflict! "Type mismatch, should be #{@type}" if data['type'] != @type

        relationships = parse_relationships data['relationships']
        Xikolo::JSONAPI::Entity.new self, data['id'], data['attributes'], relationships
      end

      def parse_relationships(data)
        return {} if data.nil?

        fail! 'Can not parse relationships' unless data.is_a? Hash

        data.to_h do |name, relationship|
          fail! 'Can not parse relationship object' unless relationship.is_a? Hash
          fail! "Relationship #{name} has no data" unless relationship.key? 'data'
          fail! "Unknown relationship #{name}" unless rel? name

          [name, rel(name).instance_from_linkage(relationship['data'])]
        end
      end

      def fail!(message)
        raise Xikolo::Error::BadRequest.new(message)
      end

      def conflict!(message)
        raise Xikolo::Error::Conflict.new(message)
      end
    end
  end
end
