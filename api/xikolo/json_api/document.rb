# frozen_string_literal: true

module Xikolo
  module JSONAPI
    class Document
      def initialize(context)
        @context = context
        @included = Set.new
        @meta = {}
        @links = {}
      end

      def data=(entity)
        @data = PrimaryData.from entity
      end

      def include!(*includes)
        @included.merge(includes.flat_map {|relation_name|
          @data.include(relation_name, @context)
        })
      end

      def meta!(key, value)
        @meta[key] = value
      end

      def link!(name, href)
        @links[name] = href
      end

      def serialize(context)
        included = @included
        meta = @meta
        links = @links

        {'data' => @data.serialize(context)}.tap {|hash|
          hash['included'] = included.map {|i| i.serialize(context) } unless included.empty?
          hash['meta'] = meta unless meta.empty?
          hash['links'] = links unless links.empty?
        }
      end

      class PrimaryData
        def self.from(entity_or_entities)
          if entity_or_entities.is_a? Array
            MultipleResourceObjects.new entity_or_entities
          else
            SingleResourceObject.new entity_or_entities
          end
        end
      end

      class MultipleResourceObjects
        def initialize(entities)
          @entities = entities
        end

        def serialize(context)
          @entities.map {|e| e.serialize(context) }
        end

        def include(relation_name, context)
          Restify::Promise.new(
            @entities.map do |entity|
              entity.related_resources_for relation_name, context
            end
          ).value!.flatten
        end
      end

      class SingleResourceObject
        def initialize(entity)
          @entity = entity
        end

        def serialize(context)
          @entity.serialize(context)
        end

        def include(relation_name, context)
          @entity.related_resources_for(relation_name, context).value!
        end
      end
    end
  end
end
