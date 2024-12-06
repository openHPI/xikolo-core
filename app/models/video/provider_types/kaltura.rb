# frozen_string_literal: true

module Video
  module ProviderTypes
    class Kaltura
      def self.credential_attributes
        %w[
          partner_id
          token
          token_id
        ]
      end
    end
  end
end
