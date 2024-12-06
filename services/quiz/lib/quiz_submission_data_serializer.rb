# frozen_string_literal: true

module QuizSubmissionDataSerializer
  class << self
    def dump(data)
      JSON.dump(data.as_json)
    end

    def load(str)
      return nil if str.blank?

      begin
        JSON.parse(str)
      rescue JSON::ParserError
        parse_legacy(str)
      end
    end

    private

    # Parse whatever crude YAML serialization had been applied before.
    #
    # This method is inspired by the source from `::Psych#parse` and
    # `#safe_load`. Only basic ruby objects are allowed to be deserialized but
    # `!ruby/hash` and `!ruby/hash-with-ivars` tags are handled and parsed as
    # plain hash objects instead of raising an exception. See `Visitor` class
    # for more details.
    #
    def parse_legacy(str)
      # The actual data is YAML serialized and the resulting string is again
      # YAML serialized. Therefore we need to first extract the string from
      # YAML and deserialize again.
      str = YAML.safe_load(str)
      raise TypeError unless str.is_a?(String)

      doc = Psych.parse(str)

      loader  = Psych::ClassLoader::Restricted.new([], [])
      scanner = Psych::ScalarScanner.new loader

      Visitor.new(scanner, loader).accept(doc)
    end

    # This custom visitor handles YAML mappings in a special way. All custom
    # class annotations from serialized Hash-like objects are ignore and only
    # parsed as a normal Hash.
    class Visitor < ::Psych::Visitors::NoAliasRuby
      def visit_Psych_Nodes_Mapping(node) # rubocop:disable Naming/MethodName
        case node.tag
          when %r{^!ruby/hash-with-ivars(?::(.*))?$}
            {}.tap do |hash|
              register(node, hash)
              node.children.each_slice(2) do |key, value|
                # Explicitly ignore `ivars` node; We only want to reconstruct
                # minimal pure hash
                revive_hash(hash, value) if key.value == 'elements'
              end
            end
          when %r{^!ruby/hash:(.*)$}
            # Explicitly use `Hash` objects instead of allocating an object from
            # the class in matcher group $1.
            revive_hash(register(node, {}), node)
          else
            super
        end
      end
    end
  end
end
