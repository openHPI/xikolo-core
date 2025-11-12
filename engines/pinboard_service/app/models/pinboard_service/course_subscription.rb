# frozen_string_literal: true

module PinboardService
class CourseSubscription < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :course_subscriptions

  default_scope { order created_at: :desc }
end
end
