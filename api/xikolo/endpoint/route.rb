# frozen_string_literal: true

module Xikolo
  module Endpoint
    class Route
      def initialize(description, handler, block)
        @description = description
        @handler = handler
        @block = block
      end

      attr_reader :description, :block

      def to_proc
        handler = @handler
        block = @block

        proc do
          context = Xikolo::Middleware::RunContext.new env

          handler.run block, context, self
        end
      end
    end
  end
end
