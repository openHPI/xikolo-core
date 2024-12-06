# frozen_string_literal: true

module Xikolo
  module Endpoint
    class EntityLink
      def initialize(name, url_generator)
        @name = name
        @url_generator = url_generator
      end

      def prepare(res)
        @url_generator.call res
      end
    end
  end
end
