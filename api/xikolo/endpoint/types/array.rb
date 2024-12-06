# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class Array < Type
        def initialize(**opts)
          super

          @type = opts[:of]
          @type = Xikolo::Endpoint::Types.make(@type) unless Xikolo::Endpoint::Types.all.any? {|t| @type.is_a? t }
        end

        def out(val)
          # unwrap restify resource
          value = if val.is_a?(Restify::Resource)
                    val.data
                  else
                    val
                  end

          return [] unless value.is_a?(::Array)

          value.map do |v|
            @type.out(v)
          end
        end

        def in(val)
          raise Xikolo::Error::InvalidValue unless val.is_a?(::Array)

          val.map do |v|
            @type.in(v)
          end
        end

        def schema
          [@type.schema || @type.name]
        end
      end
    end
  end
end
