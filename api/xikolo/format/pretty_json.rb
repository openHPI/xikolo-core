# frozen_string_literal: true

require 'json' # For the to_json helper

module Xikolo
  module Format
    module PrettyJSON
      def self.call(object, _env)
        JSON.pretty_generate object
      rescue StandardError
        '{}'
      end
    end
  end
end
