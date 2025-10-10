# frozen_string_literal: true

class CourseSubscription < ApplicationRecord
  self.table_name = :course_subscriptions

  default_scope { order created_at: :desc }
end
