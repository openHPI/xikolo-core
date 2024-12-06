# frozen_string_literal: true

module Xikolo::Course::Concerns
  module Course
    extend ActiveSupport::Concern

    STATES = %w[preparation active archive].freeze

    included do
      validates :title, :status, presence: true
      validates :status, inclusion: {in: STATES, message: '%{value} is not a valid course state'}
      validates :course_code, presence: true, format: /\A[\w-]+\z/, uniqueness: {case_sensitive: false}
    end
  end
end
