# frozen_string_literal: true

module Xikolo
  module JSONAPI
    class Entity
      def initialize(definition, id, attributes, relationships = {}, links = {})
        @definition = definition
        @id = id
        @attributes = attributes
        @relationships = relationships
        @links = links
      end

      attr_reader :id, :attributes, :relationships, :links

      def type
        @definition.type
      end

      def identifier
        {
          'type' => type,
          'id' => @id,
        }
      end

      def serialize(context)
        identifier.dup.tap {|hash|
          # Filter empty links, merge all relationship objects
          links = @links.compact_blank
          relationships = @relationships.values.each_with_object({}) {|rel, rels|
            rels.merge! rel.serialize(context)
          }

          hash['links'] = links unless links.empty?
          hash['attributes'] = @attributes.dup unless @attributes.empty?
          hash['relationships'] = relationships unless relationships.empty?
        }
      end

      def to_resource
        # Pull out all valid attributes from the data that was passed in
        attrs = @definition.attributes.map {|attr| attr.write @attributes }.reduce({}, :merge)

        attrs.merge @relationships.map {|_, rel| rel.to_resource }.reduce({}, :merge)
      end

      # Start loading all related resources for the given relationship
      def related_resources_for(relationship_name, context)
        @relationships.fetch(relationship_name).related context
      end

      def eql?(other)
        other.is_a?(self.class) && other.type == type && other.id == id
      end

      def hash
        [type, @id].hash
      end
    end
  end
end
