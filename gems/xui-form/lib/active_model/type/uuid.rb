# frozen_string_literal: true

require 'uuid4'

module ActiveModel
  module Type
    class UUID < Value
      def deserialize(value)
        if value.present?
          ::UUID4.try_convert(value)
        end
      end

      def serialize(value)
        value.to_s
      end

      def declared(model, name, _type)
        model.validates name, uuid: true
      end

      private

      def cast_value(value)
        return nil if value.blank?

        ::UUID4.try_convert(value) || value
      end
    end

    register :uuid, UUID
  end
end

class UUIDValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || value.is_a?(::UUID4)

    record.errors.add attribute, :no_uuid
  end
end
