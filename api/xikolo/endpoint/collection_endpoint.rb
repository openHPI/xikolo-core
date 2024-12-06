# frozen_string_literal: true

module Xikolo
  module Endpoint
    class CollectionEndpoint < Grape::API::Instance
      class << self
        def entity(&)
          @entity = Endpoint::EntityDefinition::Factory.new.build(&)
        end

        def entity_definition
          raise "No entity definition was found for class #{self}" unless @entity

          @entity
        end

        include Xikolo::Versioning::Subject

        def filters(&)
          filter_definition.from(&)
        end

        def filter_definition
          @filter_definition ||= Endpoint::FilterRegistration.new
        end

        def paginate!(opts = {})
          @pagination = Endpoint::Pagination.new opts
        end

        def pagination?
          !!@pagination
        end

        attr_reader :pagination

        def collection(&)
          handlers = {
            get: Xikolo::Endpoint::Handler::GetCollection.new(self),
            post: Xikolo::Endpoint::Handler::PostCollection.new(self),
          }

          Endpoint::RouteRegistration
            .new(self, handlers, collection_routes)
            .instance_exec(&)
        end

        def member(&)
          handlers = {
            get: Xikolo::Endpoint::Handler::GetMember.new(entity_definition),
            patch: Xikolo::Endpoint::Handler::PatchMember.new(entity_definition),
            delete: Xikolo::Endpoint::Handler::DeleteMember.new(entity_definition),
          }

          route_param :id do
            Endpoint::RouteRegistration
              .new(self, handlers, member_routes)
              .instance_exec(&)

            entity_definition.relationships.select(&:route?).each do |rel|
              instance_exec(&rel.route)
            end
          end
        end

        def collection_routes
          @collection_routes ||= {}
        end

        def member_routes
          @member_routes ||= {}
        end
      end
    end
  end
end
