# frozen_string_literal: true

module Xikolo::Course::Concerns
  module Section
    extend ActiveSupport::Concern

    included do
      validates :title, :course_id, presence: true
    end
  end
end
