# frozen_string_literal: true

module Voucher
  module ProductTypes
    VALID_PRODUCT_TYPES = {
      'course_reactivation' => ProductTypes::Reactivation,
      'proctoring_smowl' => ProductTypes::Proctoring,
    }.freeze

    class << self
      def enabled
        VALID_PRODUCT_TYPES.select {|_key, cls| cls.enabled? }
      end

      def resolve(type)
        VALID_PRODUCT_TYPES.fetch(type)
      end
    end
  end
end
