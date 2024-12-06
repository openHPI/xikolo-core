# frozen_string_literal: true

module Video
  module ProviderTypes
    class Vimeo
      def self.credential_attributes
        %w[token]
      end
    end
  end
end
