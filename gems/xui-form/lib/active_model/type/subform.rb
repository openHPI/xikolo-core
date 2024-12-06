# frozen_string_literal: true

module ActiveModel
  module Type
    class Subform < Value
      def initialize(klass:, **)
        @klass = klass
        super(**)
      end

      def serialize(value)
        value.to_resource
      end

      def deserialize(value)
        @klass.from_resource(value)
      end

      private

      def cast_value(value)
        @klass.from_params(value)
      end
    end

    register :subform, Subform
  end
end
