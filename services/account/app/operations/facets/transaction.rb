# frozen_string_literal: true

module Facets
  module Transaction
    extend ActiveSupport::Concern

    included do
      prepend Overlay
    end

    module Overlay
      def call(*)
        ActiveRecord::Base.transaction { super }
      end
    end
  end
end
