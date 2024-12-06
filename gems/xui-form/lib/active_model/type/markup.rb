# frozen_string_literal: true

require 'json'
require 'active_model/type/xikolo_string'

module ActiveModel
  module Type
    class Markup < XikoloString
      attr_reader :uploads

      def initialize(uploads: nil)
        @uploads = uploads
        super()
      end

      def type
        :markup
      end

      def cast_value(value)
        if value.respond_to? :to_hash
          value = value.to_hash
          value['markup'] = super(value['markup'])
          value
        else
          super
        end
      end

      def declared(model, name, _value)
        return unless uploads

        model.process_with { MarkupProcessor.new(name) }
      end

      class MarkupProcessor
        attr_reader :field_name

        def initialize(field_name)
          @field_name = field_name.to_s
        end

        def from_params(params, _obj)
          markup = params.delete(field_name)
          url_mapping = params.delete("#{field_name}_urlmapping")
          other_files = params.delete("#{field_name}_otherfiles")
          params[field_name] = {
            'markup' => markup,
            'url_mapping' => parse(url_mapping),
            'other_files' => parse(other_files),
          }
          params
        end

        def from_resource(params, _obj)
          return params if params[field_name].respond_to? :to_hash

          markup = params.delete(field_name)
          params[field_name] = {
            'markup' => markup,
            'url_mapping' => {},
            'other_files' => {},
          }
          params
        end

        def to_resource(attributes, _obj)
          return attributes unless attributes.key? field_name
          return attributes unless attributes[field_name].respond_to? :to_hash

          attributes[field_name] = attributes[field_name].to_hash['markup']
          attributes
        end

        private

        def parse(input)
          JSON.parse(input.to_s)
        rescue JSON::ParserError
          {}
        end
      end
    end

    register :markup, Markup
  end
end
