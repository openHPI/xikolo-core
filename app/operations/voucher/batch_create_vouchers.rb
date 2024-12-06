# frozen_string_literal: true

module Voucher
  ##
  # Generate multiple new product vouchers at once.
  #
  # This could be used by admins to create a batch of vouchers for a specific
  # product that could be handed out at marketing events. Another use-case may
  # be automatic retrieval of a voucher that is to be sold by a shop system.
  #
  class BatchCreateVouchers < ApplicationOperation
    MAX_VOUCHERS = 500

    ##
    # Parameters:
    # - the number of vouchers to create
    # - a hash of attributes to set on all newly created vouchers
    #
    def initialize(count, params)
      super()

      @count = count.to_i
      @params = params
    end

    Success = Struct.new(:records)

    def call
      if @count < 1
        return result error(I18n.t(:'vouchers.create.count_error'))
      elsif @count > MAX_VOUCHERS
        return result error(I18n.t(:'vouchers.create.too_many_vouchers_requested'))
      end

      ::Voucher::Voucher.transaction do
        vouchers = Array.new(@count).map { ::Voucher::Voucher.create!(@params) }
        result Success.new(vouchers)
      end
    rescue ActiveRecord::RecordInvalid => e
      result e.record.errors
    end

    private

    def error(message)
      errors = ActiveModel::Errors.new(::Voucher::Voucher.new)
      errors.add :base, message
      errors
    end
  end
end
