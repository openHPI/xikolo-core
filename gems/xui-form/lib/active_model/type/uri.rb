# frozen_string_literal: true

require 'uri'

module ActiveModel
  module Type
    class URI < Value
      def serialize(value)
        value&.to_s
      end

      def declared(model, name, _type)
        model.validates name, uri: true
      end

      private

      def cast_value(value)
        return nil if value.blank?

        ::URI.parse(value.strip)
      rescue ::URI::InvalidURIError
        value
      end
    end

    class URL < URI
      def declared(model, name, _type)
        model.validates name, xi_url: true
      end
    end

    register :uri, URI
    register :url, URL
  end
end

class URIValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || value.is_a?(::URI)

    record.errors.add attribute, :no_uri
  end
end

class XiURLValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    return if value.is_a?(::URI) && %w[http https].include?(value.scheme)

    record.errors.add attribute, :no_url
  end
end
