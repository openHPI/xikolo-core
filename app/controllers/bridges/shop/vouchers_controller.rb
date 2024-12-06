# frozen_string_literal: true

module Bridges
  module Shop
    class VouchersController < BaseController
      responders Responders::DecorateResponder,
        Responders::PaginateResponder

      respond_to :json

      def index
        vouchers = Voucher::Voucher.all

        vouchers = vouchers.where(tag: params[:tag]) if params[:tag].present?
        if params[:claimed].present?
          vouchers = vouchers.claimed_in_period(params[:start_date], params[:end_date])
        end

        respond_with(vouchers)
      end

      def create
        Voucher::BatchCreateVouchers.call(
          params[:qty], correct_in(params).permit(:product_type, :tag, :country)
        ).on do |result|
          result.success {|success| render json: decorate(success.records) }
          result.errors {|errors| render json: {errors: correct_out(errors.as_json)}, status: :unprocessable_entity }
        end
      end

      def decorate(voucher)
        return voucher.map {|v| decorate(v) } if voucher.respond_to?(:map)

        {
          id: voucher.id,
          country: voucher.country,
          product: voucher.product_type,
          tag: voucher.tag,
          created_at: voucher.created_at,
        }.tap do |fields|
          next if voucher.claimed_at.blank?

          fields.merge!(
            claimed_at: voucher.claimed_at,
            claimant_ip: voucher.claimant_ip.to_s,
            claimant_country: voucher.claimant_country
          )
        end
      end

      private

      # Rename attributes for backward compatibility with old service API
      def correct_in(params)
        params.tap do |p|
          p[:product_type] = p.delete(:product) if p.key?(:product)
        end
      end

      def correct_out(params)
        params.tap do |p|
          p[:product] = p.delete(:product_type) if p.key?(:product_type)
        end
      end
    end
  end
end
