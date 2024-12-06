# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      MAP = {
        datetime: Types::DateTime,
        bool: Types::Boolean,
        boolean: Types::Boolean,
        int: Types::Integer,
        integer: Types::Integer,
        float: Types::Float,
        string: Types::String,
        hash: Types::Hash,
        array: Types::Array,
      }.freeze

      class << self
        def make(type, **)
          (MAP[type] || Types::Any).new(**)
        end

        def all
          MAP.values
        end
      end
    end
  end
end
