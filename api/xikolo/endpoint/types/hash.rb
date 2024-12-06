# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class Hash < Type
        def initialize(**opts)
          super

          @schema = opts[:of] || {}
          @schema.each do |k, v|
            @schema[k] = Xikolo::Endpoint::Types.make(v) unless Xikolo::Endpoint::Types.all.any? {|t| v.is_a? t }
          end
        end

        def out(val)
          # unwrap restify resource
          value = if val.is_a?(Restify::Resource)
                    val.data
                  else
                    val
                  end

          # if val is not a hash return a valid hash with schema keys and default values
          unless value.is_a?(::Hash)
            return @schema.stringify_keys.transform_values do |type|
              type.out(nil)
            end
          end

          hash = value.stringify_keys
          if @schema.empty?
            # arbitrary keys allowed
            hash.to_h
          else
            # only specified keys allowed
            @schema.stringify_keys.each_with_object({}) do |(key, type), result|
              result[key] = type.out(hash[key])
            end
          end
        end

        def in(val)
          raise Xikolo::Error::InvalidValue unless val.is_a?(::Hash)

          types = @schema.stringify_keys
          if @schema.empty?
            # arbitrary keys allowed
            val
          else
            # only specified keys allowed
            val.stringify_keys.each_with_object({}) do |(key, value), result|
              type = types[key]
              result[key] = type.in(value) if type
            end
          end
        end

        def schema
          if @schema.empty?
            {any: :any}
          else
            @schema.stringify_keys.transform_values do |type|
              type.schema || type.name
            end
          end
        end
      end
    end
  end
end
