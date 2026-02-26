# frozen_string_literal: true

module Voucher
  module ProductTypes
    VALID_PRODUCT_TYPES = {
      'course_reactivation' => ProductTypes::Reactivation,
    }.freeze

    class << self
      def resolve(type)
        VALID_PRODUCT_TYPES.fetch(type)
      end
    end
  end
end
