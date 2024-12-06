# frozen_string_literal: true

require 'active_support/concern'

module XUI
  class Form
    #
    # Implements ActiveModel's persistence interface for forms.
    #
    # Adds the ActiveModel method #persisted? and its opposite #new_record?,
    # which are useful for determining a form's target URL and HTTP method.
    #
    # The methods' return values are based on an instance variable.
    #
    module Persistence
      extend ActiveSupport::Concern

      def persisted?
        @persisted
      end

      def new_record?
        !persisted?
      end

      def persisted!
        @persisted = true
      end

      def initialize(attrs = {})
        @persisted = false

        # Replicate ActiveModel's default constructor
        @attributes = self.class._default_attributes.deep_dup

        _assign_attributes_from(source: :database, attrs:)
      end

      private

      def _assign_attributes_from(source:, attrs:)
        (self.class.attribute_types.keys & attrs.keys).each do |key|
          @attributes.public_send(:"write_from_#{source}", key, attrs[key])
        end
      end

      class_methods do
        def from_params(params)
          if params.respond_to?(:require)
            params = params.require(model_name.singular)
            params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : {}
          else
            params = params.to_hash # convert & create own copy
          end

          new.tap do |object|
            attrs = object.send(:process_from, source: :params, attrs: params)
            object.send(:_assign_attributes_from, source: :user, attrs:)
          end
        end

        def from_resource(resource)
          new.tap do |object|
            attrs = object.send(:process_from, source: :resource, attrs: resource.to_hash)
            object.send(:_assign_attributes_from, source: :database, attrs:)

            object.persisted!
          end
        end
      end
    end
  end
end
