# frozen_string_literal: true

module Voucher
  class Claim < ApplicationOperation
    # @param course [Course::Course]
    def initialize(voucher, product_type, course, user, **opts)
      super()

      @voucher = ::Voucher::Voucher.find_by(id: voucher)
      @product_type = product_type
      @course = course
      @user = user
      @opts = opts
    end

    Success = Struct.new(:message)
    Error = Struct.new(:message)

    ##
    # Validate the preconditions for the voucher and product type,
    # and try claiming the voucher if they are fulfilled.
    #
    def call
      # Anonymous users are not allowed to redeem vouchers. This should be
      # prevented by the caller of this operation, i.e. the controller.
      # Therefore, respond with a general error (which is not displayed).
      return error('general') if @user.anonymous?

      # Early return if the voucher does not exist.
      return error('not_found') if @voucher.blank?

      # Is the voucher claimed for the correct product type?
      return error('incorrect_product') if @voucher.product_type != @product_type.type

      # Ensure all product prerequisites are fulfilled.
      # Is the requested product enabled, i.e. available in the course?
      return result Error.new(@product_type.unavailable_message) unless @product_type.enabled_in?(@course)
      # Is the user allowed to redeem the voucher for this product type, i.e. activate the product?
      return result Error.new(product.error) unless product.valid?

      # Claim the voucher and the actual product.
      # Abort and roll back if any error occurs.
      ActiveRecord::Base.transaction do
        @voucher.claim!(
          claimant_id: @user.id,
          claimant_ip: @opts.fetch(:claimant_ip),
          course_id: @course.id
        )

        product.claim!
      end

      result Success.new(product.success_message)
    rescue ActiveRecord::RecordInvalid => e
      # Show a message for validation errors when claiming the voucher.
      if e.record.errors['claimant']&.first == 'immutable'
        return error('wrong_claimant')
      elsif e.record.errors['course']&.first == 'immutable'
        return error('wrong_course')
      end

      error('general')
    rescue ::Voucher::Errors::Problem => e
      # Show a message for domain errors while claiming the voucher.
      error(e.reason)
    rescue Restify::ResponseError
      # Show a message for product activation (Restify calls to xi-course) errors.
      error('general')
    end
    # rubocop:enable all

    private

    ##
    # The actual product that is claimed for a specific user in
    # a specific course, based on the given product type.
    #
    def product
      @product ||= @product_type.new(@course, @user)
    end

    def error(type)
      result Error.new I18n.t(:"flash.error.voucher.#{type}")
    end
  end
end
