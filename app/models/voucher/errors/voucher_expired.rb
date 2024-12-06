# frozen_string_literal: true

module Voucher
  module Errors
    class VoucherExpired < Problem
      def initialize(reason = 'expired')
        super
      end
    end
  end
end
