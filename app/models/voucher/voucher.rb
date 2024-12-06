# frozen_string_literal: true

require 'geo_ip/lookup'

module Voucher
  class Voucher < ::ApplicationRecord
    belongs_to :course, class_name: 'Course::Course', optional: true

    validates :country, :product_type, presence: {message: 'required'}
    validate :validate_product_type
    validate :validate_claim_attrs, if: :claimed?
    validates :claimant_ip,
      presence: {message: 'required'},
      if: :claimed?,
      unless: :claimant_ip_may_be_removed?
    # Require a valid ISO 3166-1 alpha-3 country code, i.e. three letters.
    validates :claimant_country,
      format: {with: /\A[A-Z]{3}\z/, message: 'invalid'},
      if: :claimed?

    class << self
      def claimed
        where.not(claimed_at: nil)
      end

      def claimed_in_period(start_date, end_date)
        if start_date.blank? && end_date.blank?
          claimed
        else
          where('claimed_at < ? AND claimed_at > ?',
            end_date.to_date.end_of_day, start_date.to_date.beginning_of_day)
        end
      end
    end

    def claimed?
      claimed_at.present?
    end

    def claimant_ip_may_be_removed?
      claimed_at <= 1.year.ago
    end

    def expired?
      expires_at && expires_at < Time.zone.now
    end

    def claim!(claimant_id:, claimant_ip:, course_id:)
      raise ::Voucher::Errors::VoucherExpired if expired?

      claimed_at = Time.zone.now

      transaction do
        raise ::Voucher::Errors::AlreadyClaimed if claimed?

        update!(
          claimant_id:,
          course_id:,
          claimed_at:,
          claimant_ip:,
          claimant_country: country_for(claimant_ip)
        )
      end
    end

    private

    def validate_product_type
      ::Voucher::ProductTypes.resolve(product_type) if product_type.present?
    rescue KeyError
      errors.add :product_type, 'invalid'
    end

    def validate_claim_attrs
      return if claimed_at.blank?

      errors.add :course, 'required' if course_id.blank?
      errors.add :claimant, 'required' if claimant_id.blank?

      if claimant_id_changed? && !claimant_id_was.nil?
        errors.add :claimant, 'immutable'
      end

      errors.add :course, 'immutable' if course_id_changed? && !course_id_was.nil?
    end

    def country_for(ip)
      lookup = GeoIP::Lookup.resolve(ip)

      # Use user-assigned code if GeoIP data cannot be fetched.
      return 'AAA' unless lookup.found?

      ISO3166::Country.new(lookup.country.iso_code).alpha3
    rescue IPAddr::Error
      # A valid IP address is required, error might be raised by the GeoIP lookup.
      errors.add :claimant_ip, 'invalid'
    end
  end
end
