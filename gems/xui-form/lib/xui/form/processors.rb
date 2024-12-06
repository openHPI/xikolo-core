# frozen_string_literal: true

require 'active_support/concern'

module XUI
  class Form
    #
    # Implements in- and output processing
    # The allows to pass in the params and let the form extract all its fields
    # it also applied processors that can apply arbitrary input manipulations
    #
    # A new `to_resource` methods returns the attributes data with output
    # processors applied.
    #
    module Processors
      extend ActiveSupport::Concern

      def to_resource
        # Loop over all attributes and get their "database" value, which we
        # use to generate the resource that is sent to a backend server. This
        # ensures the underlying +ActiveModel::Type+'s #serialize method will
        # be called.
        original = self.class.attribute_types.to_h do |key, _|
          [key, @attributes[key].value_for_database]
        end

        process_to(target: :resource, attrs: original)
      end

      private

      def processors
        # Instantiate, then memoize processor instances for this form instance
        @processors ||= self.class.processors.map(&:call)
      end

      ##
      # Run the attributes through the processor pipeline for the given source
      #
      def process_from(source:, attrs:)
        processors.reduce(attrs) do |prev, processor|
          method = :"from_#{source}"

          if processor.respond_to?(method)
            processor.public_send(method, prev, self)
          else
            prev
          end
        end
      end

      ##
      # Run the attributes through the processor pipeline for the given target
      #
      def process_to(target:, attrs:)
        processors.reduce(attrs) do |prev, processor|
          method = :"to_#{target}"

          if processor.respond_to?(method)
            processor.public_send(method, prev, self)
          else
            prev
          end
        end
      end

      class_methods do
        def processors
          @processors ||= []
        end

        def process_with(&block)
          processors << block
        end
      end
    end
  end
end
