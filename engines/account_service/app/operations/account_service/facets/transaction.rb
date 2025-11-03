# frozen_string_literal: true

module AccountService
module Facets # rubocop:disable Layout/IndentationWidth
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
end
