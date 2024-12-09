# frozen_string_literal: true

module Xikolo
  module Endpoint
    class SingularEndpoint < Grape::API::Instance
      class << self
        def entity(&)
          @entity = Endpoint::EntityDefinition::Factory.new.build(&)
        end

        def entity_definition
          raise "No entity definition was found for class #{self}" unless @entity

          @entity
        end

        include Xikolo::Versioning::Subject

        def member(&)
          handlers = {
            get: Xikolo::Endpoint::Handler::GetMember.new(entity_definition),
            patch: Xikolo::Endpoint::Handler::PatchMember.new(entity_definition),
            delete: Xikolo::Endpoint::Handler::DeleteMember.new(entity_definition),
          }

          Endpoint::RouteRegistration
            .new(self, handlers, member_routes)
            .instance_exec(&)

          entity_definition.relationships.select(&:route?).each do |rel|
            instance_exec(&rel.route)
          end
        end

        def member_routes
          @member_routes ||= {}
        end

        def collection_routes
          @collection_routes ||= {}
        end
      end
    end
  end
end
