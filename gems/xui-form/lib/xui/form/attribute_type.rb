# frozen_string_literal: true

module XUI
  class Form
    #
    # Provides the method SimpleForm expects for looking up the
    # attribute type.
    #
    module AttributeType
      def type_for_attribute(name)
        dynamic_attributes[name]&.fetch(:type) || self.class.attribute_types[name]
      end

      def has_attribute?(name) # rubocop:disable Naming/PredicateName
        dynamic_attributes.key?(name) || self.class.attribute_types[name].present?
      end
    end
  end
end
