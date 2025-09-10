# frozen_string_literal: true

class CourseSubscription < ApplicationRecord
  default_scope { order created_at: :desc }
end
