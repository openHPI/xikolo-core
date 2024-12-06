# frozen_string_literal: true

module Voucher
  module Errors
    class Problem < StandardError
      attr_reader :reason

      def initialize(reason)
        super
        @reason = reason
      end
    end
  end
end
