# frozen_string_literal: true

require 'active_model/type/xikolo_string'

module ActiveModel
  module Type
    class SingleLineString < XikoloString
      def declared(model, name, _type)
        model.validates name, single_line_string: true
      end
    end

    register :single_line_string, SingleLineString
  end
end

class SingleLineStringValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || !value.include?("\n") # rubocop:disable Rails/NegateInclude

    record.errors.add attribute, :single_line_string
  end
end
