# frozen_string_literal: true

module Xikolo
  module Versioning
    class Handler
      def initialize(wrapped_handler, constraint)
        @handler = wrapped_handler
        @constraint = constraint
      end

      def run(block, context, grape)
        ensure_constraint_satisfied! context.env['XIKOLO_API_VERSION']

        @handler.run(block, context, grape)
      end

      private

      def ensure_constraint_satisfied!(version)
        raise Xikolo::Error::NotFound unless @constraint.satisfy? version
      end
    end
  end
end
