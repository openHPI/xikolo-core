# frozen_string_literal: true

# Every course has an offer with a default price of 0.
# There may be multiple offers for the same course with different prices,
# categories, and payment frequencies.
module Course
  class Offer < ApplicationRecord
    self.table_name = 'course_offers'

    CURRENCIES = %w[EUR].freeze
    PAYMENT_FREQUENCIES = %w[one_time weekly monthly quarterly half_yearly by_semester yearly other].freeze
    CATEGORIES = %w[course certificate complete].freeze

    belongs_to :course

    validates :price, numericality: {greater_than_or_equal_to: 0, only_integer: true}, presence: true
    validates :price_currency, inclusion: {in: CURRENCIES}, presence: true
    validates :category, inclusion: {in: CATEGORIES}, presence: true
    validates :payment_frequency, inclusion: {in: PAYMENT_FREQUENCIES}, presence: true

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with Offer instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'CourseOffer')
    end

    def to_param
      id
    end

    def formatted_price
      (price.to_d / 100).to_s('F')
    end
  end
end
