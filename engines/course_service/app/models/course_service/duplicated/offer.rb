# frozen_string_literal: true

module CourseService
# Every course has an offer with a default price of 0.
# There may be multiple offers for the same course with different prices,
# categories, and payment frequencies.
module Duplicated # rubocop:disable Layout/IndentationWidth
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
  end
end
end
