# frozen_string_literal: true

module Xikolo::Course::Concerns
  module Enrollment
    extend ActiveSupport::Concern

    included do
      validates :user_id, :course_id, presence: true
    end
  end
end
