# frozen_string_literal: true

require 'active_support/concern'

module XUI
  class Form
    #
    # Expose readers for attributes that do not exist.
    #
    # This is sometimes needed for making nested data structures compatible
    # with SimpleForm, which expects attributes to be readable with one
    # method call on the "top level".
    #
    # The readers can be defined by type-specific processors.
    #
    module DynamicAttributes
      def method_missing(method, *args, **kwargs, &)
        name = method.to_s
        attribute = dynamic_attributes[name]
        return super unless attribute

        attribute[:getter].call(@attributes, name)
      end

      def respond_to_missing?(method, include_private = false)
        dynamic_attributes[method.to_s].presence || super
      end

      private

      def dynamic_attributes
        @dynamic_attributes ||= processors.reduce({}) do |prev, processor|
          if processor.respond_to?(:attributes)
            prev.merge processor.attributes(self)
          else
            prev
          end
        end
      end
    end
  end
end
