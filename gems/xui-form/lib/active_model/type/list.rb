# frozen_string_literal: true

module ActiveModel
  module Type
    class List < Value
      def initialize(subtype:, subtype_opts: {}, **)
        @subtype = ActiveModel::Type.lookup(subtype, **subtype_opts)
        super(**)
      end

      def serialize(value)
        value.map do |subvalue|
          @subtype.serialize(subvalue)
        end
      end

      def deserialize(value)
        return [] if value.nil?

        value.map do |subvalue|
          @subtype.deserialize(subvalue)
        end
      end

      private

      def cast_value(value)
        return [] if value.nil?

        value.filter_map do |subvalue|
          @subtype.cast(subvalue)
        end
      end
    end

    register :list, List
  end
end
