# frozen_string_literal: true

module Xikolo
  module Endpoint
    class EntityAttribute
      class Factory
        def initialize(name)
          @name = name
          @desc = ''

          @opts = {}
        end

        def build(&specification)
          instance_exec(&specification) if specification

          EntityAttribute.new @name, @type, @desc, **@opts
        end

        def type(name, **)
          @type = make_type(name, **)
        end

        def make_type(name, **)
          Xikolo::Endpoint::Types.make(name, **)
        end
        alias nested_type make_type

        def description(text)
          @desc = text
        end

        def alias_for(key)
          @opts[:alias] = key
        end

        def version(constraints = {})
          @opts[:version_constraint] = Xikolo::Versioning::Constraint.from_hash constraints
        end

        # Provide a block to decorate an attribute before exposing it
        #
        # The block will receive the entire resource (a hash with string keys) upon serialization.
        def reading(&transformer)
          @opts[:read_transformer] = transformer
        end

        # Provide a block to parse an attribute value passed in from a request
        #
        # The block will receive only the attribute value to which it can apply transformations. If
        # the transformer returns a hash, this hash will be merged with the other attributes as-is.
        # This can be used to pass a different key name to the backend. If any other type is returned,
        # the configured attribute name will be used as key instead.
        def writing(&transformer)
          @opts[:write_transformer] = transformer
        end

        # Map attribute values with the given hash
        #
        # Works both ways *only if the mapping is invertible*.
        def map(hash)
          @opts[:map] = hash
        end
      end

      def initialize(name, type, desc = '', opts = {})
        @name = name
        @type = type
        @desc = desc

        raise 'All attributes need a type' unless @type

        @alias = opts[:alias]
        @member_only = opts.fetch(:member_only, false)
        @writable = opts.fetch(:writable, false)
        @version_constraint = opts[:version_constraint] || Xikolo::Versioning::Constraint.any

        if opts[:map]
          @read_transformer = proc {|resource|
            # The resource's attribute value should be found as a key in the hash.
            # If not, we will simply expose the original value.
            key = @alias || @name
            opts[:map].fetch(resource[key], resource[key])
          }

          # Check whether the hash is invertible
          inverted = opts[:map].invert
          if (@writable_map = opts[:map].count.eql? inverted.count)
            @write_transformer = proc {|val|
              key = @alias || @name
              {key => inverted.fetch(val, val)}
            }
          end
        else
          @read_transformer = opts[:read_transformer]
          @write_transformer = opts[:write_transformer]
          @writable_map = true
        end
      end

      attr_accessor :member_only
      attr_reader :desc, :name, :version_constraint
      attr_writer :writable

      def type_name
        @type.name
      end

      def type_schema
        JSON.pretty_generate(@type.schema) if @type.schema
      end

      # Whether this attribute can be set by requests
      def can_write?
        @writable && @writable_map
      end

      # Expose the attribute to the user
      #
      # Selects the data from the resource, if available, and applies any
      # transformations and aliases.
      def read(resource)
        value = if @read_transformer
                  @read_transformer.call resource
                else
                  resource[@alias || @name]
                end

        {@name => @type.out(value)}
      end

      # Extract the attribute from user-submitted data, if possible
      #
      # Returns a hash that can be merged with the hashes from other attributes.
      # The hash will be empty if no matching data was provided or when the attribute may not be written.
      def write(data)
        return {} unless data.key?(@name) && can_write?

        user_value = @type.in(data[@name])

        if @write_transformer
          apply_write_transformer user_value
        else
          key = @alias || @name

          {key => user_value}
        end
      end

      private

      def apply_write_transformer(val)
        transformed = @write_transformer.call val

        transformed = {@name => transformed} unless transformed.is_a? Hash

        transformed
      end
    end
  end
end
