# frozen_string_literal: true

module Voucher
  module Errors
    class AlreadyClaimed < Problem
      def initialize(reason = 'already_claimed')
        super
      end
    end
  end
end
