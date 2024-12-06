# frozen_string_literal: true

module ActiveModel
  module Type
    class Hash < Value
      def initialize(subtype:, keys:, **)
        @subtype = subtype
        @keys = keys
        super(**)
      end

      def serialize(value)
        value.transform_values do |subvalue|
          @subtype.serialize(subvalue)
        end
      end

      def deserialize(value)
        return {} if value.nil?

        value.transform_values do |subvalue|
          @subtype.deserialize(subvalue)
        end
      end

      def declared(model, name, _value)
        model.process_with { HashProcessor.new(name, @subtype, keys: LazyKeys.new(@keys)) }
      end

      private

      def cast_value(value)
        return {} if value.nil?

        value.transform_values do |subvalue|
          @subtype.cast(subvalue)
        end.compact
      end

      class HashProcessor
        attr_reader :field_name

        def initialize(field_name, subtype, keys:)
          @field_name = field_name.to_s
          @subtype = subtype
          @keys = keys
        end

        def attributes(object)
          @keys.for(object).to_h do |key|
            name = "#{field_name}_#{key}"
            [name, {
              attribute: ActiveModel::Attribute.uninitialized(name, @subtype),
              type: @subtype,
              getter: proc {|attributes|
                attributes[field_name].value&.dig(key)
              },
            }]
          end
        end

        def from_params(params, object)
          field = {}
          @keys.for(object).each do |key|
            field[key] = params["#{field_name}_#{key}"] if params["#{field_name}_#{key}"].present?
            params.delete "#{field_name}_#{key}"
          end
          params[field_name] = field
          params
        end
      end

      class LazyKeys
        def initialize(keys)
          @generator = if keys.respond_to?(:to_proc)
                         keys.to_proc
                       elsif keys.respond_to?(:call)
                         keys
                       else
                         proc { keys }
                       end
        end

        def for(model)
          @keys ||= @generator.call(model).map(&:to_s)

          self
        end

        def each(&)
          raise 'Must be called on a model' unless @keys

          @keys.each(&)
        end

        include Enumerable
      end
    end

    register :hash, Hash
  end
end
